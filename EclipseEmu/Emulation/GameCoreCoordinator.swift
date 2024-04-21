import Foundation
import GameController
import QuartzCore
import EclipseKit
import simd

protocol GameCoreCoordinatorTouchControlsDelegate {
    var valueChangedHandler: ((UInt32) -> Void)? { get set }
}

// FIXME: this needs better running state.
//  i.e. if someone hides the app with the game paused, then comes back, it shouldn't resume the game until the user does.

actor GameCoreCoordinator: GameCoreDelegate {
    enum Failure: Error {
        case failedToGetMetalDevice
        case failedToCreateFullscreenQuad
        case failedToCreatePipelineState
        case failedToCreateTheCommandQueue
        case failedToCreateSamplerState
    }
    
    var width: CGFloat = 0.0
    var height: CGFloat = 0.0
    
    private let core: GameCore
    /// SAFTEY: since we never write, this should not be an issue
    nonisolated(unsafe) private(set) var isRunning: Bool = false
    /// SAFTEY: this is only nonisolated so the touch controller can attach itself, otherwise no mutations occur.
    nonisolated(unsafe) private(set) var inputs: GameInputCoordinator
    /// SAFTEY: this is an actor itself and it is only nonisolated so the ring buffer can be written to syncronously by the core.
    nonisolated(unsafe) private let audio: GameAudio
    /// SAFTEY: this is only nonisolated so the game screen can add the layer to its layer hierarchy.
    nonisolated(unsafe) let renderingSurface: CAMetalLayer

    // NOTE: in the future this should be handled properly
    private var renderer: GameRenderer
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private(set) var rate: Double = 1.0
    private var frameTimerTask: Task<Void, Never>?
    
    init(core: GameCore, system: GameSystem) throws {
        self.core = core

        core.setup(system: system)
        
        self.desiredFrameRate = core.getDesiredFrameRate()
        self.frameDuration = 1.0 / desiredFrameRate
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw Failure.failedToGetMetalDevice
        }
        
        let width = core.getVideoWidth()
        let height = core.getVideoHeight()
        self.width = CGFloat(width)
        self.height = CGFloat(height)
        
        self.renderingSurface = .init()
        self.renderingSurface.contentsScale = 2.0
        self.renderingSurface.drawableSize = .init(width: width, height: height)
        self.renderingSurface.device = device
        self.renderingSurface.framebufferOnly = true
        self.renderingSurface.isOpaque = true
        self.renderingSurface.presentsWithTransaction = true
        #if canImport(AppKit)
        self.renderingSurface.displaySyncEnabled = true
        #endif
        
        switch core.getVideoRenderingType() {
        case .frameBuffer:
            let pixelFormat = core.getVideoPixelFormat()
            self.renderer = try GameRenderer2D(with: device, pixelFormat: pixelFormat, core: self.core, desiredFrameRate: desiredFrameRate)
            try self.renderer.update()
            break
        }
        
        self.audio = try GameAudio(format: core.getAudioFormat())
        
        self.inputs = .init(maxPlayers: core.getMaxPlayers())
        self.core.delegate = self
    }
    
    deinit {
        core.stop()
        core.takedown()
    }
    
    func start(gameUrl: URL) async {
        guard self.core.start(url: gameUrl) else { return }
        await self.inputs.start()
        await self.audio.start()
        await self.play()
    }
    
    func stop() async {
        await self.pause()
        self.core.stop()
        self.inputs.stop()
        await self.audio.stop()
        self.core.takedown()
    }
    
    func restart() async {
        if self.isRunning {
            await self.audio.pause()
            self.frameTimerTask?.cancel()
            self.frameTimerTask = nil
        }
        await self.audio.clear()
        self.core.restart()
        self.startFrameTimer()
        await self.audio.resume()
        self.isRunning = true
    }
    
    func play() async {
        guard !self.isRunning else { return }
        self.core.play()
        self.startFrameTimer()
        await self.audio.resume()
        self.isRunning = true
    }
    
    func pause() async {
        guard self.isRunning else { return }
        self.core.pause()
        await self.audio.pause()
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil
        self.isRunning = false
    }
    
    func renderFrame() {
        self.renderer.render(in: self.renderingSurface)
    }
    
    // MARK: Core Delegate methods
    
    nonisolated func coreRenderAudio(samples: UnsafeRawPointer, byteSize: UInt64) -> UInt64 {
        return self.audio.write(samples: samples, count: byteSize)
    }
    
    nonisolated func coreDidSave(at path: URL) {
        print(path)
    }

    // MARK: Frame Timing

    func setFastForward(enabled: Bool) {
        let rate: Double = enabled ? 2 : 1
        self.rate = rate
        #if canImport(AppKit)
        self.renderingSurface.displaySyncEnabled = !enabled
        #endif
        self.renderer.useAdaptiveSync = !enabled
        self.frameDuration = (1.0 / desiredFrameRate) / rate
    }
    
    func startFrameTimer() {
        self.frameTimerTask?.cancel()
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

                // FIXME: is this a good position in the loop?
                self.inputs.poll()
                for (i, player) in self.inputs.players.enumerated() {
                    self.core.playerSetInputs(player: UInt8(i), value: player.state)
                }
                
                while time <= expectedTime {
                    time += frameDuration
                    let doRender = time >= expectedTime && expectedTime >= nextRenderTime
                    nextRenderTime = doRender ? expectedTime + renderInterval : nextRenderTime
                    
                    self.core.executeFrame(processVideo: doRender)
                    if doRender {
                        self.renderFrame()
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
        return self.core.playerConnected(player: player)
    }
    
    func playerDisconnected(player: UInt8) {
        return self.core.playerDisconnected(player: player)
    }
}
