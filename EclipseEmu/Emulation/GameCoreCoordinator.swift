import Foundation
import GameController
import QuartzCore
import simd
import EclipseKit

enum GameVideoRenderer {
    case frameBuffer(GameFrameBufferRenderer)
}

// FIXME: this needs better running state.
//  i.e. if someone hides the app with the game paused, then comes back, it shouldn't resume the game until the user does.
actor GameCoreCoordinator {
    enum Failure: Error {
        case failedToGetCoreInstance
        case failedToGetMetalDevice
        
        case invalidPixelFormat
        case invalidAudioFormat
        case invalidRendererFormat
    }
    
    var width: CGFloat = 0.0
    var height: CGFloat = 0.0
    
    private let core: UnsafeMutablePointer<GameCore>
    let inputs: GameInputCoordinator
    /// FIXME: this should be isolated and there should be some sort of notification to indicate changes in state
    nonisolated(unsafe) private(set) var isRunning: Bool = false
    /// SAFTEY: this is an actor itself and it is only nonisolated so the ring buffer can be written to syncronously by the core.
    nonisolated(unsafe) private let audio: GameAudio
    /// SAFTEY: this is only nonisolated so the game screen can add the layer to its layer hierarchy.
    nonisolated(unsafe) let renderingSurface: CAMetalLayer

    // NOTE: in the future this should be handled properly
    private var renderer: GameVideoRenderer
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private var frameTimerTask: Task<Void, Never>?
    private(set) var rate: Double = 1.0
    private let callbackContext: UnsafeMutablePointer<CallbackContext>
    
    struct CallbackContext {
        var audio: GameAudio!
    }
    
    private static let writeAudio: EKCoreAudioWriteCallback = { ctx, ptr, count in
        // SAFETY:
        //  audio is set at the end of the init block.
        //  ctx should always be passed back in and will only be nil when the actor deinits.
        //  if the core doesn't remove all references to it then it needs to, branching here would be awful for perf.
        //  it is like 99% likely that ctx will not be nil, so even an unlikely branch would be excessive.
        let audio = ctx!.assumingMemoryBound(to: CallbackContext.self).pointee.audio!
        return audio.write(samples: ptr.unsafelyUnwrapped, count: count)
    }
    
    private static let didSave: EKCoreSaveCallback = { savePathPtr in
        guard let savePathPtr else { return }
        let savePath = String(cString: savePathPtr)
    }
    
    init(coreInfo: GameCoreInfo, system: GameSystem, reorderControls: @escaping GameInputCoordinator.ReorderControllersCallback) throws {
        self.callbackContext = UnsafeMutablePointer<CallbackContext>.allocate(capacity: 1)
        self.callbackContext.initialize(to: CallbackContext())
        
        let coreCallbacksPtr = UnsafeMutablePointer<GameCoreCallbacks>.allocate(capacity: 1)
        coreCallbacksPtr.initialize(to: GameCoreCallbacks(
            callbackContext: self.callbackContext,
            didSave: Self.didSave,
            writeAudio: Self.writeAudio
        ))

        guard let core = coreInfo.setup(system, coreCallbacksPtr) else {
            throw Failure.failedToGetCoreInstance
        }
        
        self.core = core
        
        self.desiredFrameRate = core.pointee.getDesiredFrameRate(core.pointee.data)
        self.frameDuration = 1.0 / desiredFrameRate
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw Failure.failedToGetMetalDevice
        }
        
        let videoFormat = core.pointee.getVideoFormat(core.pointee.data)
        
        let width =  videoFormat.width
        let height = videoFormat.height
        
        self.width = CGFloat(width)
        self.height = CGFloat(height)
        let size = CGSize(width: self.width, height: self.height)
        
        self.renderingSurface = .init()
        self.renderingSurface.contentsScale = 2.0
        self.renderingSurface.drawableSize = size
        self.renderingSurface.device = device
        self.renderingSurface.framebufferOnly = true
        self.renderingSurface.isOpaque = true
        self.renderingSurface.presentsWithTransaction = true
        #if canImport(AppKit)
        self.renderingSurface.displaySyncEnabled = true
        #endif
        
        switch videoFormat.renderingType {
        case .frameBuffer:
            guard let pixelFormat = videoFormat.pixelFormat.metal else { throw Failure.invalidPixelFormat }
            let renderer = try GameFrameBufferRenderer(
                with: device,
                width: Int(width),
                height: Int(height),
                pixelFormat: pixelFormat,
                frameDuration: frameDuration,
                core: core
            )
            self.renderer = .frameBuffer(renderer)
            break
        @unknown default:
            throw Failure.invalidRendererFormat
        }
        
        guard let audioFormat = core.pointee.getAudioFormat(core.pointee.data).avAudioFormat else {
            throw Failure.invalidAudioFormat
        }
                
        
        self.audio = try GameAudio(format: audioFormat)
        self.callbackContext.pointee.audio = self.audio

        self.inputs = .init(maxPlayers: core.pointee.getMaxPlayers(core.pointee.data), reorderPlayers: reorderControls)
    }
    
    deinit {
        core.pointee.stop(core.pointee.data)
        core.pointee.deallocate(core.pointee.data)
        core.deallocate()
        callbackContext.deallocate()
    }
    
    func start(gamePath: URL, savePath: URL?) async {
        guard self.core.pointee.start(
            self.core.pointee.data,
            gamePath.absoluteString.cString(using: .ascii),
            savePath?.absoluteString.cString(using: .ascii)
        ) else { return }
        await self.inputs.start()
        await self.audio.start()
        await self.play()
    }
    
    func stop() async {
        await self.pause()
        self.core.pointee.stop(core.pointee.data)
        self.inputs.stop()
        await self.audio.stop()
    }
    
    func restart() async {
        if self.isRunning {
            await self.audio.pause()
            self.frameTimerTask?.cancel()
            self.frameTimerTask = nil
        }
        await self.audio.clear()
        self.core.pointee.restart(core.pointee.data)
        self.startFrameTimer()
        await self.audio.resume()
        self.isRunning = true
    }
    
    func play() async {
        guard !self.isRunning else { return }
        self.core.pointee.play(core.pointee.data)
        self.startFrameTimer()
        await self.audio.resume()
        self.isRunning = true
    }
    
    func pause() async {
        guard self.isRunning else { return }
        self.core.pointee.pause(core.pointee.data)
        await self.audio.pause()
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil
        self.isRunning = false
    }
    
    // MARK: Frame Timing

    func setFastForward(enabled: Bool) {
        let rate: Double = enabled ? 2 : 1
        self.rate = rate
        #if canImport(AppKit)
        self.renderingSurface.displaySyncEnabled = !enabled
        #endif
        
        let newFrameDuration = (1.0 / desiredFrameRate) / rate
        switch self.renderer {
        case .frameBuffer(let renderer):
            renderer.useAdaptiveSync = !enabled
            renderer.frameDuration = newFrameDuration
        }
        self.frameDuration = newFrameDuration
    }
    
    func startFrameTimer() {
        self.frameTimerTask?.cancel()
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

                    self.inputs.poll()
                    for (i, player) in self.inputs.players.enumerated() {
                        self.core.pointee.playerSetInputs(self.core.pointee.data, UInt8(i), player.state)
                    }

                    while time <= expectedTime {
                        time += frameDuration
                        let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                        nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime

                        self.core.pointee.executeFrame(self.core.pointee.data, doRender)
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
            //  This version may be slightly less accurate because of the way MonotomicClock.sleep is implemented, hence having both.
            //  I don't think there's any way to make this more accurate with public APIs, without blocking a thread (which defeats the purpose of a Task)
            self.frameTimerTask = Task(priority: .userInitiated) {
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
                    
                    self.inputs.poll()
                    for (i, player) in self.inputs.players.enumerated() {
                        self.core.pointee.playerSetInputs(self.core.pointee.data, UInt8(i), player.state)
                    }
                    
                    while time <= expectedTime {
                        time += frameDuration
                        let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                        nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime
                        
                        self.core.pointee.executeFrame(self.core.pointee.data, doRender)
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
        return self.core.pointee.playerConnected(self.core.pointee.data, player)
    }
    
    func playerDisconnected(player: UInt8) {
        return self.core.pointee.playerDisconnected(self.core.pointee.data, player)
    }
}
