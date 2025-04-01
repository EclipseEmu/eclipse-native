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

enum GameCoreCoordinatorError: Error {
    case failedToGetCoreInstance
    case invalidPixelFormat
    case invalidAudioFormat
    case invalidRendererFormat
}

final actor GameCoreCoordinator {
    private let executor: BlockingSerialExecutor
    nonisolated let unownedExecutor: UnownedSerialExecutor

    let width: CGFloat
    let height: CGFloat

    private nonisolated(unsafe) let core: UnsafeMutablePointer<GameCore>

    let inputs: GameInputCoordinator
    private(set) var state: GameCoreCoordinatorState = .stopped
    let audio: GameAudio

    private let renderer: VideoRenderer
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private var frameTimerTask: Task<Void, Never>?
    private(set) var rate: Float = 1.0
    private nonisolated(unsafe) let callbackContext: UnsafeMutablePointer<CallbackContext>
    private nonisolated(unsafe) let callbacks: UnsafeMutablePointer<GameCoreCallbacks>

    struct CallbackContext {
        weak var parent: GameCoreCoordinator?
    }

    private static let writeAudio: EKCoreAudioWriteCallback = { ctx, ptr, count in
        // SAFETY: ctx should always be passed back in and will only be nil when the actor deinits.
        let context = ctx!.assumingMemoryBound(to: CallbackContext.self)

        let coreCoordinator = context.pointee.parent
        guard _fastPath(coreCoordinator != nil) else { return 0 }
        return UInt64(coreCoordinator!.audio.write(samples: ptr.unsafelyUnwrapped, count: Int(count)))
    }

    private static let didSave: EKCoreSaveCallback = { ctx in
        // SAFETY: ctx should always be passed back in and will only be nil when the actor deinits.
        let context = ctx!.assumingMemoryBound(to: CallbackContext.self)

        let coreCoordinator = context.pointee.parent
        guard _fastPath(coreCoordinator != nil) else { return }

        Task { @MainActor in
            NotificationCenter.default.post(name: .EKGameCoreDidSave, object: nil)
        }
    }

    init(
        coreInfo: CoreInfo,
        game: ObjectBox<Game>,
        system: GameSystem,
        bindingsManager: ControlBindingsManager
    ) async throws {
        let queue = DispatchQueue(label: "dev.magnetar.eclipseemu.queue.corecoordinator")
        self.executor = BlockingSerialExecutor(queue: queue)
        self.unownedExecutor = executor.asUnownedSerialExecutor()

        do {
            callbackContext = UnsafeMutablePointer<CallbackContext>.allocate(capacity: 1)
            callbackContext.initialize(to: CallbackContext())

            callbacks = UnsafeMutablePointer<GameCoreCallbacks>.allocate(capacity: 1)
            callbacks.initialize(to: GameCoreCallbacks(
                callbackContext: callbackContext,
                didSave: Self.didSave,
                writeAudio: Self.writeAudio
            ))

            guard let core = coreInfo.setup(system, callbacks) else {
                throw GameCoreCoordinatorError.failedToGetCoreInstance
            }

            try Task.checkCancellation()

            self.core = core

            desiredFrameRate = core.pointee.getDesiredFrameRate(core.pointee.data)
            frameDuration = 1.0 / desiredFrameRate

            let videoFormat = core.pointee.getVideoFormat(core.pointee.data)
            let width = videoFormat.width
            let height = videoFormat.height
            self.width = CGFloat(width)
            self.height = CGFloat(height)

            try Task.checkCancellation()

            switch videoFormat.renderingType {
            case .frameBuffer:
                guard let pixelFormat = videoFormat.pixelFormat.metal else {
                    throw GameCoreCoordinatorError.invalidPixelFormat
                }
                let graphicsContext = try await GlobalMetalContext()
                let renderer: FrameBufferRenderer
                if core.pointee.canSetVideoPointer(core.pointee.data) {
                    renderer = try await FrameBufferRenderer(
                        context: graphicsContext,
                        width: Int(width),
                        height: Int(height),
                        pixelFormat: pixelFormat,
                        pointer: nil
                    )
                    let pointer = await renderer.getBufferPointer()
                    _ = core.pointee.getVideoPointer(core.pointee.data, pointer.value)
                } else {
                    let buf = UnsafeMutableRawPointer(mutating: core.pointee.getVideoPointer(core.pointee.data, nil))
                    renderer = try await FrameBufferRenderer(
                        context: graphicsContext,
                        width: Int(width),
                        height: Int(height),
                        pixelFormat: pixelFormat,
                        pointer: buf.map { .init($0) }
                    )
                }

                self.renderer = .frameBuffer(renderer)
            @unknown default:
                throw GameCoreCoordinatorError.invalidRendererFormat
            }

            try Task.checkCancellation()

            guard let audioFormat = core.pointee.getAudioFormat(core.pointee.data).avAudioFormat else {
                throw GameCoreCoordinatorError.invalidAudioFormat
            }

            audio = try GameAudio(format: audioFormat)
            inputs = await GameInputCoordinator(
                maxPlayers: core.pointee.getMaxPlayers(core.pointee.data),
                game: game,
                system: system,
                bindingsManager: bindingsManager
            )

            try Task.checkCancellation()

            callbackContext.pointee.parent = self
        } catch {
            callbackContext.deallocate()
            callbacks.deallocate()
            throw error
        }
    }

    deinit {
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil

        core.pointee.clearCheats(core.pointee.data)
        core.pointee.stop(core.pointee.data)
        core.pointee.deallocate(core.pointee.data)
        core.deallocate()
        callbackContext.deallocate()
        callbacks.deallocate()
    }

    func start(gamePath: URL, savePath: URL) async {
        guard self.core.pointee.start(
            self.core.pointee.data,
            gamePath.path(percentEncoded: false).cString(using: .ascii),
            savePath.path(percentEncoded: false).cString(using: .ascii)
        ) else { return }
        await inputs.start()
        await audio.start()
        await play(reason: .stopped)
    }

    func stop() async {
        await pause(reason: .stopped)
        core.pointee.stop(core.pointee.data)
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
        core.pointee.restart(core.pointee.data)
        startFrameTimer()
        await audio.resume()
        state = .running
    }

    func play(reason: GameCoreCoordinatorState) async {
        guard state.rawValue <= reason.rawValue else { return }
        state = .running
        core.pointee.play(core.pointee.data)
        startFrameTimer()
        await audio.resume()
    }

    func pause(reason: GameCoreCoordinatorState) async {
        guard state.rawValue < reason.rawValue || reason == .stopped else { return }
        state = reason

        frameTimerTask?.cancel()
        frameTimerTask = nil

        core.pointee.pause(core.pointee.data)
        await audio.pause()
    }

    // MARK: Saving

    func save(to url: URL) -> Bool {
        core.pointee.save(core.pointee.data, url.path)
    }

    func saveState(to url: URL) -> Bool {
        return core.pointee.saveState(core.pointee.data, url.path)
    }

    @discardableResult
    func loadState(for url: URL) -> Bool {
        return core.pointee.loadState(core.pointee.data, url.path)
    }

    // MARK: Cheats

    /// - Parameter cheats: A list of cheats to add
    /// - Returns: A set of the cheats that failed to set.
    func setCheats(cheats: [OwnedCheat]) -> Set<OwnedCheat>? {
        core.pointee.clearCheats(core.pointee.data)
        var response: Set<OwnedCheat>?
        for cheat in cheats {
            guard let type = cheat.type, let code = cheat.code else { continue }
            let wasSuccessful = core.pointee.setCheat(core.pointee.data, type, code, cheat.enabled)
            if !wasSuccessful {
                response = response ?? Set()
                response!.insert(cheat)
            }
        }
        return response
    }

    // MARK: Frame Timing

    func setFastForward(enabled: Bool) {
        let rate: Float = enabled ? 2.0 : 1.0
        self.rate = rate
//        #if canImport(AppKit)
//        renderingSurface.displaySyncEnabled = !enabled
//        #endif

        Task {
            await audio.setRate(rate: rate)
        }
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
                    self.core.pointee.playerSetInputs(
                        self.core.pointee.data,
                        i,
                        inputs.states[Int(i)].load(ordering: .relaxed)
                    )
                }

                while time <= expectedTime {
                    time += frameDuration
                    let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                    nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime

                    self.core.pointee.executeFrame(self.core.pointee.data, doRender)
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
        return core.pointee.playerConnected(core.pointee.data, player)
    }

    func playerDisconnected(player: UInt8) {
        return core.pointee.playerDisconnected(core.pointee.data, player)
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
