import AVFoundation
import Combine
import CoreGraphics
import EclipseKit
import Foundation
import GameController
import MetalKit
import simd

extension NSNotification.Name {
    static let EKGameCoreDidSave = NSNotification.Name("EKGameCoreDidSaveNotification")
}

final actor GameCoreCoordinator: Sendable {
    enum VideoRenderer {
        case frameBuffer(GameFrameBufferRenderer)
    }

    enum State: UInt8, RawRepresentable {
        case stopped = 0
        case running = 1
        case backgrounded = 2
        case pendingUserInput = 3
        case paused = 4
    }

    enum Failure: Error {
        case failedToGetCoreInstance
        case failedToGetMetalDevice
        case failedToStart

        case invalidPixelFormat
        case invalidAudioFormat
        case invalidRendererFormat
    }

    let width: CGFloat
    let height: CGFloat

    private nonisolated(unsafe) let corePointer: UnsafeMutablePointer<GameCore>
    private nonisolated(unsafe) let callbackContext: UnsafeMutablePointer<CallbackContext>
    private nonisolated(unsafe) let callbacks: UnsafeMutablePointer<GameCoreCallbacks>

    @usableFromInline
    var core: GameCore {
        corePointer.pointee
    }

    let inputs: GameInputCoordinator
    // FIXME: there should be some sort of notification to indicate changes in state
    private(set) var state: State = .stopped
    /// SAFTEY: this is an actor itself and it is only nonisolated so the ring buffer
    ///     can be written to syncronously by the core.
    nonisolated(unsafe) let audio: GameAudio
    /// SAFTEY: this is only nonisolated so the game screen can add the layer to its layer hierarchy.
    nonisolated(unsafe) let renderingSurface: CAMetalLayer

    private let renderer: VideoRenderer
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private var frameTimerTask: Task<Void, Never>?
    private(set) var rate: Float = 1.0

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

    init(coreInfo: GameCoreInfo, system: GameSystem, surface: CAMetalLayer) throws {
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
                throw Failure.failedToGetCoreInstance
            }

            try Task.checkCancellation()

            corePointer = core

            desiredFrameRate = core.pointee.getDesiredFrameRate(core.pointee.data)
            frameDuration = 1.0 / desiredFrameRate

            guard let device = MTLCreateSystemDefaultDevice() else {
                throw Failure.failedToGetMetalDevice
            }

            try Task.checkCancellation()

            let videoFormat = core.pointee.getVideoFormat(core.pointee.data)
            let width = videoFormat.width
            let height = videoFormat.height
            self.width = CGFloat(width)
            self.height = CGFloat(height)

            renderingSurface = surface
            renderingSurface.drawableSize = CGSize(width: self.width, height: self.height)
            renderingSurface.device = device
            renderingSurface.contentsScale = 1.0
            renderingSurface.needsDisplayOnBoundsChange = true
            renderingSurface.framebufferOnly = true
            renderingSurface.isOpaque = true
            renderingSurface.presentsWithTransaction = true
            #if canImport(AppKit)
            renderingSurface.displaySyncEnabled = true
            #endif

            try Task.checkCancellation()

            switch videoFormat.renderingType {
            case .frameBuffer:
                guard let pixelFormat = videoFormat.pixelFormat.metal else { throw Failure.invalidPixelFormat }
                renderingSurface.pixelFormat = pixelFormat
                let renderer = try GameFrameBufferRenderer(
                    with: device,
                    width: Int(width),
                    height: Int(height),
                    pixelFormat: pixelFormat,
                    frameDuration: frameDuration,
                    core: core
                )
                self.renderer = .frameBuffer(renderer)
            @unknown default:
                throw Failure.invalidRendererFormat
            }

            try Task.checkCancellation()

            guard let audioFormat = core.pointee.getAudioFormat(core.pointee.data).avAudioFormat else {
                throw Failure.invalidAudioFormat
            }

            audio = try GameAudio(format: audioFormat)
            inputs = .init(maxPlayers: core.pointee.getMaxPlayers(core.pointee.data))

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

        corePointer.pointee.clearCheats(corePointer.pointee.data)
        corePointer.pointee.stop(corePointer.pointee.data)
        corePointer.pointee.deallocate(corePointer.pointee.data)
        corePointer.deallocate()
        callbackContext.deallocate()
        callbacks.deallocate()
    }

    func start(gamePath: URL, savePath: URL) async throws {
        guard corePointer.pointee.start(
            corePointer.pointee.data,
            gamePath.path.cString(using: .ascii),
            savePath.path.cString(using: .ascii)
        ) else {
            throw Failure.failedToStart
        }
        await inputs.start()
        await audio.start()
        await play(reason: .stopped)
    }

    func stop() async {
        await pause(reason: .stopped)
        corePointer.pointee.stop(corePointer.pointee.data)
        inputs.stop()
        await audio.stop()
    }

    func restart() async {
        if state == .running {
            await audio.pause()
            frameTimerTask?.cancel()
            frameTimerTask = nil
        }
        audio.clear()
        corePointer.pointee.restart(corePointer.pointee.data)
        startFrameTimer()
        await audio.resume()
        state = .running
    }

    func play(reason: State) async {
        guard state.rawValue <= reason.rawValue else { return }
        state = .running
        corePointer.pointee.play(corePointer.pointee.data)
        startFrameTimer()
        await audio.resume()
    }

    func pause(reason: State) async {
        guard state.rawValue < reason.rawValue || reason == .stopped else { return }
        state = reason

        frameTimerTask?.cancel()
        frameTimerTask = nil

        corePointer.pointee.pause(corePointer.pointee.data)
        await audio.pause()
    }

    // MARK: Saving

    func save(to url: URL) -> Bool {
        corePointer.pointee.save(corePointer.pointee.data, url.path)
    }

    func saveState(to url: URL) -> Bool {
        return corePointer.pointee.saveState(corePointer.pointee.data, url.path)
    }

    func loadState(for url: URL) -> Bool {
        return corePointer.pointee.loadState(corePointer.pointee.data, url.path)
    }

    // MARK: Cheats

    /// - Parameter cheats: A list of cheats to add
    /// - Returns: A set of the cheats that failed to set.
    func setCheats(cheats: [EmulationData.CheatData]) -> [EmulationData.CheatData] {
        corePointer.pointee.clearCheats(corePointer.pointee.data)
        var response = [EmulationData.CheatData]()
        for cheat in cheats {
            let wasSuccessful = corePointer.pointee.setCheat(corePointer.pointee.data, cheat.type, cheat.code, true)
            if !wasSuccessful {
                response.append(cheat)
            }
        }
        return response
    }

    // MARK: Frame Timing

    func setFastForward(enabled: Bool) {
        let rate: Float = enabled ? 2.0 : 1.0
        self.rate = rate
        #if canImport(AppKit)
        renderingSurface.displaySyncEnabled = !enabled
        #endif

        audio.setRate(rate: rate)
        let newFrameDuration = (1.0 / desiredFrameRate) / Double(rate)
        switch renderer {
        case .frameBuffer(let renderer):
            renderer.useAdaptiveSync = !enabled
            renderer.frameDuration = newFrameDuration
        }
        frameDuration = newFrameDuration
    }

    // swiftlint:disable:next cyclomatic_complexity
    func startFrameTimer() {
        frameTimerTask?.cancel()
        if #available(iOS 16.0, macOS 12.0, *) {
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

                    self.corePointer.pointee.playerSetInputs(self.corePointer.pointee.data, 0, inputs.players[0].state)

                    while time <= expectedTime {
                        time += frameDuration
                        let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                        nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime

                        self.corePointer.pointee.executeFrame(self.corePointer.pointee.data, doRender)
                        if doRender {
                            switch self.renderer {
                            case .frameBuffer(let renderer):
                                renderer.render(in: self.renderingSurface)
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
        } else {
            // NOTE:
            //  This version may be slightly less accurate because of the way MonotomicClock.sleep is implemented,
            //  hence having both. I don't think there's any way to make this more accurate, with public APIs,
            //  without blocking a thread (which defeats the purpose of a Task)
            frameTimerTask = Task(priority: .userInitiated) {
                let initialTime: MonotomicClock.Instant = MonotomicClock.now
                var time: MonotomicClock.Duration = 0
                let renderInterval: MonotomicClock.Duration = MonotomicClock.seconds(1.0 / 60.0)
                var nextRenderTime: MonotomicClock.Duration = 0

                while !Task.isCancelled {
                    let start: MonotomicClock.Instant = MonotomicClock.now
                    let frameDuration: MonotomicClock.Duration = MonotomicClock.seconds(self.frameDuration)
                    let maxCatchupRate: MonotomicClock.Duration = MonotomicClock.seconds(5 * self.frameDuration)
                    let expectedTime = start - initialTime
                    time = max(time, UInt64(expectedTime > maxCatchupRate) * (expectedTime &- maxCatchupRate))

                    for (playerIndex, player) in self.inputs.players.enumerated() {
                        self.corePointer.pointee.playerSetInputs(self.corePointer.pointee.data, UInt8(playerIndex), player.state)
                    }

                    while time <= expectedTime {
                        time += frameDuration
                        let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                        nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime

                        self.corePointer.pointee.executeFrame(self.corePointer.pointee.data, doRender)
                        if doRender {
                            switch self.renderer {
                            case .frameBuffer(let renderer):
                                renderer.render(in: self.renderingSurface)
                            }
                        }
                    }

                    let framesTime: MonotomicClock.Duration = MonotomicClock.now - start
                    if framesTime < frameDuration {
                        try? await MonotomicClock.sleep(until: start + frameDuration)
                    } else {
                        await Task.yield()
                    }
                }
            }
        }
    }

    // MARK: Input handling

    func playerConnected(player: UInt8) -> Bool {
        return corePointer.pointee.playerConnected(corePointer.pointee.data, player)
    }

    func playerDisconnected(player: UInt8) {
        return corePointer.pointee.playerDisconnected(corePointer.pointee.data, player)
    }

    // MARK: Screenshot

    func writeScreenshot(to path: Files.Path) async throws {
        guard 
            case .image = path,
            let url = path.path(in: .shared)
        else { return }


        let colorSpace = renderingSurface.colorspace ?? CGColorSpaceCreateDeviceRGB()

        let result = switch renderer {
        case .frameBuffer(let renderer):
            renderer.screenshot(colorSpace: colorSpace)
        }

        let image = result ?? CIImage.black
        try CIContext().writeJPEGRepresentation(of: image, to: url, colorSpace: colorSpace)
    }
}
