import Foundation
import GameController
import MetalKit
import simd
import EclipseKit
import Combine
import AVFoundation

extension NSNotification.Name {
    static let EKGameCoreDidSave = NSNotification.Name.init("EKGameCoreDidSaveNotification")
}

fileprivate enum GameVideoRenderer {
    case frameBuffer(GameFrameBufferRenderer)
}

final actor GameCoreCoordinator {
    enum State: UInt8, RawRepresentable {
        case stopped = 0
        case running = 1
        case pendingUserInput = 2
        case backgrounded = 3
        case paused = 4
    }
    
    enum Failure: Error {
        case failedToGetCoreInstance
        case failedToGetMetalDevice
        
        case invalidPixelFormat
        case invalidAudioFormat
        case invalidRendererFormat
    }
    
    let width: CGFloat
    let height: CGFloat
    
    private let core: UnsafeMutablePointer<GameCore>
    private let game: Game
    
    let inputs: GameInputCoordinator
    /// FIXME: there should be some sort of notification to indicate changes in state
    private(set) var state: State = .stopped
    /// SAFTEY: this is an actor itself and it is only nonisolated so the ring buffer can be written to syncronously by the core.
    nonisolated(unsafe) let audio: GameAudio
    /// SAFTEY: this is only nonisolated so the game screen can add the layer to its layer hierarchy.
    nonisolated(unsafe) let renderingSurface: CAMetalLayer

    private let renderer: GameVideoRenderer
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private var frameTimerTask: Task<Void, Never>?
    private(set) var rate: Float = 1.0
    private let callbackContext: UnsafeMutablePointer<CallbackContext>
    private let callbacks: UnsafeMutablePointer<GameCoreCallbacks>

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
        game: Game,
        coreInfo: GameCoreInfo,
        system: GameSystem,
        surface: CAMetalLayer,
        reorderControls: @escaping GameInputCoordinator.ReorderControllersCallback
    ) throws {
        do {
            self.game = game
            
            self.callbackContext = UnsafeMutablePointer<CallbackContext>.allocate(capacity: 1)
            self.callbackContext.initialize(to: CallbackContext())
            
            self.callbacks = UnsafeMutablePointer<GameCoreCallbacks>.allocate(capacity: 1)
            self.callbacks.initialize(to: GameCoreCallbacks(
                callbackContext: self.callbackContext,
                didSave: Self.didSave,
                writeAudio: Self.writeAudio
            ))
            
            guard let core = coreInfo.setup(system, callbacks) else {
                throw Failure.failedToGetCoreInstance
            }
            
            self.core = core
            
            self.desiredFrameRate = core.pointee.getDesiredFrameRate(core.pointee.data)
            self.frameDuration = 1.0 / desiredFrameRate
            
            guard let device = MTLCreateSystemDefaultDevice() else {
                throw Failure.failedToGetMetalDevice
            }
            
            let videoFormat = core.pointee.getVideoFormat(core.pointee.data)
            
            let width = videoFormat.width
            let height = videoFormat.height
            
            self.width = CGFloat(width)
            self.height = CGFloat(height)
            let size = CGSize(width: self.width, height: self.height)
            
            self.renderingSurface = surface
            self.renderingSurface.drawableSize = size
            self.renderingSurface.device = device
            self.renderingSurface.contentsScale = 1.0
            self.renderingSurface.needsDisplayOnBoundsChange = true
            self.renderingSurface.framebufferOnly = true
            self.renderingSurface.isOpaque = true
            self.renderingSurface.presentsWithTransaction = true
#if canImport(AppKit)
            self.renderingSurface.displaySyncEnabled = true
#endif
            
            switch videoFormat.renderingType {
            case .frameBuffer:
                guard let pixelFormat = videoFormat.pixelFormat.metal else { throw Failure.invalidPixelFormat }
                self.renderingSurface.pixelFormat = pixelFormat
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
            self.inputs = .init(maxPlayers: core.pointee.getMaxPlayers(core.pointee.data), reorderPlayers: reorderControls)
            
            self.callbackContext.pointee.parent = self
        } catch {
            self.callbackContext.deallocate()
            self.callbacks.deallocate()
            throw error
        }
    }
    
    deinit {
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil
        
        let _ = core.pointee.clearCheats(core.pointee.data)
        core.pointee.stop(core.pointee.data)
        core.pointee.deallocate(core.pointee.data)
        core.deallocate()
        callbackContext.deallocate()
        callbacks.deallocate()
    }
    
    func start(gamePath: URL, savePath: URL) async {
        if #available(iOS 16.0, *) {
            guard self.core.pointee.start(
                self.core.pointee.data,
                gamePath.path(percentEncoded: false).cString(using: .ascii),
                savePath.path(percentEncoded: false).cString(using: .ascii)
            ) else { return }
        } else {
            guard self.core.pointee.start(
                self.core.pointee.data,
                gamePath.path.cString(using: .ascii),
                savePath.path.cString(using: .ascii)
            ) else { return }
        }
        await self.inputs.start()
        await self.audio.start()
        await self.play(reason: .stopped)
    }
    
    func stop() async {
        await self.pause(reason: .stopped)
        self.core.pointee.stop(core.pointee.data)
        self.inputs.stop()
        await self.audio.stop()
    }
    
    func restart() async {
        if self.state == .running {
            await self.audio.pause()
            self.frameTimerTask?.cancel()
            self.frameTimerTask = nil
        }
        self.audio.clear()
        self.core.pointee.restart(core.pointee.data)
        self.startFrameTimer()
        await self.audio.resume()
        self.state = .running
    }
    
    func play(reason: State) async {
        guard self.state.rawValue <= reason.rawValue else { return }
        self.state = .running
        self.core.pointee.play(core.pointee.data)
        self.startFrameTimer()
        await self.audio.resume()
    }
    
    func pause(reason: State) async {
        guard self.state.rawValue < reason.rawValue || reason == .stopped else { return }
        self.state = reason
        
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil
        
        self.core.pointee.pause(core.pointee.data)
        await self.audio.pause()
    }
    
    // MARK: Saving
    
    func save(to url: URL) -> Bool {
        self.core.pointee.save(self.core.pointee.data, url.path)
    }
    
    func saveState(to url: URL) -> Bool {
        return self.core.pointee.saveState(self.core.pointee.data, url.path)
    }
    
    func loadState(for url: URL) -> Bool {
        return self.core.pointee.loadState(self.core.pointee.data, url.path)
    }

    // MARK: Cheats
    
    /// - Parameter cheats: A list of cheats to add
    /// - Returns: A set of the cheats that failed to set.
    func setCheats(cheats: Set<Cheat>) -> Set<Cheat>? {
        self.core.pointee.clearCheats(self.core.pointee.data)
        var response: Set<Cheat>?
        for cheat in cheats {
            guard let type = cheat.type, let code = cheat.code else { continue }
            // FIXME: what to do when this fails
            let wasSuccessful = self.core.pointee.setCheat(self.core.pointee.data, type, code, cheat.enabled)
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
        #if canImport(AppKit)
        self.renderingSurface.displaySyncEnabled = !enabled
        #endif
        
        self.audio.setRate(rate: rate)
        let newFrameDuration = (1.0 / desiredFrameRate) / Double(rate)
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

                    self.core.pointee.playerSetInputs(self.core.pointee.data, 0, inputs.players[0].state);
                    
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
            //  I don't think there's any way to make this more accurate, with public APIs, without blocking a thread (which defeats the purpose of a Task)
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
                    
                    for (i, player) in self.inputs.players.enumerated() {
                        self.core.pointee.playerSetInputs(self.core.pointee.data, UInt8(i), player.state);
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
