import System
import AVFoundation
import CoreGraphics
import EclipseKit
import Foundation
import GameController
import MetalKit
import simd

extension NSNotification.Name {
    static let EKGameCoreDidSave = NSNotification.Name("EKGameCoreDidSaveNotification")
}

private enum VideoRenderer {
    case frameBuffer(FrameBufferRenderer)
}

enum GameCoreCoordinatorState: UInt8, RawRepresentable {
    case stopped = 0
    case running = 1
    case backgrounded = 2
    case pendingUserInput = 3
    case paused = 4
}

enum GameCoreCoordinatorError: LocalizedError {
    case cancelled
    case failedToGetCoreInstance
    case invalidPixelFormat
    case invalidAudioFormat
    case invalidRendererFormat

    case frameBufferRenderer(FrameBufferRendererError)
    case globalMetalContext(GlobalMetalContextError)
}

private func checkCancellation() throws(GameCoreCoordinatorError) {
    do {
        try Task.checkCancellation()
    } catch {
        throw .cancelled
    }
}

final actor GameCoreCoordinator {
    struct CallbackContext {
        weak var parent: GameCoreCoordinator?
    }

    private let executor: BlockingSerialExecutor
    nonisolated let unownedExecutor: UnownedSerialExecutor

    let width: CGFloat
    let height: CGFloat

    private let core: Core
    nonisolated let coreID: String

    let inputs: GameInputCoordinator
    private(set) var state: GameCoreCoordinatorState = .stopped
    let audio: GameAudio

    private let renderer: VideoRenderer
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private var frameTimerTask: Task<Void, Never>?
    private(set) var rate: Float = 1.0

    static let writeAudio: EKCoreAudioWriteCallback = { ctx, ptr, count in
        // SAFETY: ctx should always be passed back in and will only be nil when the actor deinits.
        let context = ctx!.assumingMemoryBound(to: CallbackContext.self)
        guard let coordinator = context.pointee.parent else { return 0 }
        _onFastPath()
        let written = UInt64(coordinator.audio.write(samples: ptr.unsafelyUnwrapped, count: Int(count)))
        return written
    }

    static let didSave: EKCoreSaveCallback = { ctx in
        Task { @MainActor in
            NotificationCenter.default.post(name: .EKGameCoreDidSave, object: nil)
        }
    }

    init(
        coreInfo: CoreInfo,
        game: ObjectBox<GameObject>,
        system: GameSystem,
        bindingsManager: ControlBindingsManager
    ) async throws(GameCoreCoordinatorError) {
        let queue = DispatchQueue(label: "dev.magnetar.eclipseemu.queue.corecoordinator")
        self.executor = BlockingSerialExecutor(queue: queue)
        self.unownedExecutor = executor.asUnownedSerialExecutor()
        self.coreID = coreInfo.id

        let callbacks = CoreCallbacks()
        guard let core = Core(from: coreInfo, system: system, callbacks: callbacks) else {
            throw .failedToGetCoreInstance
        }

        try checkCancellation()

        desiredFrameRate = core.getDesiredFrameRate()
        frameDuration = 1.0 / desiredFrameRate

        let videoFormat = core.getVideoFormat()
        let width = videoFormat.width
        let height = videoFormat.height
        self.width = CGFloat(width)
        self.height = CGFloat(height)

        try checkCancellation()

        let graphicsContext: GlobalMetalContext
        do {
            graphicsContext = try await GlobalMetalContext()
        } catch {
            throw GameCoreCoordinatorError.globalMetalContext(error)
        }

        switch videoFormat.renderingType {
        case .frameBuffer:
            guard let pixelFormat = videoFormat.pixelFormat.metal else {
                throw GameCoreCoordinatorError.invalidPixelFormat
            }
            let renderer: FrameBufferRenderer
                if core.canSetVideoPointer() {
                    do {
                        renderer = try await FrameBufferRenderer(
                            context: graphicsContext,
                            width: Int(width),
                            height: Int(height),
                            pixelFormat: pixelFormat,
                            pointer: nil
                        )
                    } catch {
                        throw GameCoreCoordinatorError.frameBufferRenderer(error)
                    }
                    let pointer = await renderer.getBufferPointer()
                    _ = core.getVideoPointer(setting: pointer.value)
                } else {
                    let buf = UnsafeMutableRawPointer(mutating: core.getVideoPointer(setting: nil))
                    do {
                        renderer = try await FrameBufferRenderer(
                            context: graphicsContext,
                            width: Int(width),
                            height: Int(height),
                            pixelFormat: pixelFormat,
                            pointer: buf.map { .init($0) }
                        )
                    } catch {
                        throw GameCoreCoordinatorError.frameBufferRenderer(error)
                    }
                }

            self.renderer = .frameBuffer(renderer)
        @unknown default:
            throw GameCoreCoordinatorError.invalidRendererFormat
        }

        try checkCancellation()

        guard let audioFormat = core.getAudioFormat().avAudioFormat else {
            throw GameCoreCoordinatorError.invalidAudioFormat
        }

        audio = try GameAudio(format: audioFormat)
        inputs = await GameInputCoordinator(
            maxPlayers: core.getMaxPlayers(),
            game: game,
            system: system,
            bindingsManager: bindingsManager
        )

        try checkCancellation()
        self.core = core
        self.core.setCallbacksParent(to: self)
    }

    deinit {
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil
    }

    func start(gamePath: URL, savePath: URL) async {
        guard core.start(game: gamePath, save: savePath) else { return }
        await inputs.start()
        await audio.start()
        await play(reason: .stopped)
    }

    func stop() async {
        await pause(reason: .stopped)
        core.stop()
        await inputs.stop()
        await audio.stop()
    }

    func restart() async {
        if state == .running {
            await audio.pause()
            frameTimerTask?.cancel()
            frameTimerTask = nil
        }
        await audio.clear()
        core.restart()
        startFrameTimer()
        await audio.resume()
        state = .running
    }

    func play(reason: GameCoreCoordinatorState) async {
        guard state.rawValue <= reason.rawValue else { return }
        state = .running
        core.play()
        startFrameTimer()
        await audio.resume()
    }

    func pause(reason: GameCoreCoordinatorState) async {
        guard state.rawValue < reason.rawValue || reason == .stopped else { return }
        state = reason

        frameTimerTask?.cancel()
        frameTimerTask = nil

        core.pause()
        await audio.pause()
    }

    // MARK: Saving

    @inlinable
    func save(to url: URL) -> Bool {
        core.save(to: url)
    }

    @inlinable
    func saveState(to url: URL) -> Bool {
        return core.saveState(to: url)
    }

    @inlinable
    @discardableResult
    func loadState(for url: URL) -> Bool {
        return core.loadState(from: url)
    }

    // MARK: Cheats

    /// - Parameter cheats: A list of cheats to add
    /// - Returns: A set of the cheats that failed to set.
    func setCheats(cheats: [Cheat]) -> Set<Cheat>? {
        core.clearCheats()
        var response: Set<Cheat>?
        for cheat in cheats {
            guard let type = cheat.type, let code = cheat.code else { continue }
            let wasSuccessful = core.setCheat(type, code, cheat.enabled)
            if !wasSuccessful {
                response = response ?? Set()
                response!.insert(cheat)
            }
        }
        return response
    }

    // MARK: Frame Timing

    func setFastForward(enabled: Bool) async {
        let rate: Float = enabled ? 2.0 : 1.0
        self.rate = rate
//        #if canImport(AppKit)
//        renderingSurface.displaySyncEnabled = !enabled
//        #endif

        await audio.setRate(rate: rate)
        let newFrameDuration = (1.0 / desiredFrameRate) / Double(rate)
        switch renderer {
        case .frameBuffer:
            // FIXME: todo
            // renderer.useAdaptiveSync = !enabled
            // renderer.frameDuration = newFrameDuration
            break
        }
        frameDuration = newFrameDuration
    }

    // swiftlint:disable:next cyclomatic_complexity
    func startFrameTimer() {
        frameTimerTask?.cancel()
        self.frameTimerTask = Task(priority: .userInitiated) {
            let initialTime: ContinuousClock.Instant = .now
            var time: ContinuousClock.Duration = .zero
            let renderInterval: ContinuousClock.Duration = .seconds(1.0 / 60.0)
            var nextRenderTime: ContinuousClock.Duration = .zero

            while !Task.isCancelled {
                let start: ContinuousClock.Instant = .now
                let frameDuration: ContinuousClock.Duration = .seconds(self.frameDuration)
                let maxCatchupRate: ContinuousClock.Duration = .seconds(5 * self.frameDuration)
                let expectedTime = start - initialTime
                time = max(time, expectedTime - maxCatchupRate)

                for i in 0..<inputs.playerCount.load(ordering: .relaxed) {
                    core.playerSetInputs(i, inputs.states[Int(i)].load(ordering: .relaxed))
                }

                while time <= expectedTime {
                    time += frameDuration
                    let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                    nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime

                    core.executeFrame(willRender: doRender)
                    if doRender {
                        switch self.renderer {
                        case .frameBuffer(let renderer):
                            await renderer.render()
                        }
                    }
                }

                let framesTime: ContinuousClock.Duration = .now - start
                if framesTime < frameDuration {
                    try? await Task.sleep(until: start + frameDuration)
                } else {
                    await Task.yield()
                }
            }
        }
    }

    // MARK: Input handling

    func playerConnected(player: UInt8) -> Bool {
        return core.playerConnected(player)
    }

    func playerDisconnected(player: UInt8) {
        return core.playerDisconnected(player)
    }

    // MARK: Video

    @MainActor
    func attach(surface: CAMetalLayer) {
        switch renderer {
        case .frameBuffer(let renderer):
            renderer.attach(surface: surface)
        }
    }

    func screenshot() async -> CIImage {
        let result = switch renderer {
        case .frameBuffer(let renderer):
            await renderer.screenshot()
        }
        return result ?? CIImage.black
    }
}
