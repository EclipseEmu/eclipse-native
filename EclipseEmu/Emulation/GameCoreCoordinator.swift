import Foundation
import GameController
import QuartzCore
import EclipseKit
import simd

protocol GameCoreCoordinatorTouchControlsDelegate {
    var valueChangedHandler: ((UInt32) -> Void)? { get set }
}

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
    
    // SAFTEY: since we never write, this should not be an issue
    nonisolated(unsafe) private(set) var isRunning: Bool = false
    
    private let core: GameCore
    var inputs: GameInputCoordinator
//    private var inputs: [UInt32] = [0]
    
    // SAFTEY: this is only set once
    nonisolated(unsafe) var touchControlsDelegate: GameCoreCoordinatorTouchControlsDelegate?
    
    // SAFTEY: this is an actor itself, there should be no real issue
    private nonisolated(unsafe) let audio: GameAudio
    
    private var renderer: GameRenderer
    private(set) nonisolated(unsafe) var renderingSurface: CAMetalLayer

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
        await self.audio.start()
        await self.play()
    }
    
    func stop() async {
        await self.pause()
        self.core.stop()
//        self.stopListeningForInputs()
        await self.audio.stop()
    }
    
    func restart() async {
        if self.isRunning {
            await self.audio.pause()
            self.frameTimerTask?.cancel()
            self.frameTimerTask = nil
        }
        await self.audio.clear()
//        self.stopListeningForInputs()
        self.core.restart()
//        self.startListeningForInputs()
        self.startFrameTimer()
        await self.audio.resume()
        self.isRunning = true
    }
    
    func play() async {
        guard !self.isRunning else { return }
//        self.startListeningForInputs()
        self.core.play()
        self.startFrameTimer()
        await self.audio.resume()
        self.isRunning = true
    }
    
    func pause() async {
        guard self.isRunning else { return }
        self.core.pause()
//        self.stopListeningForInputs()
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

//    func startListeningForInputs() {
//        // listen for new connections
//        
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil) { note in
//            guard let controller = note.object as? GCController, let gamepad = controller.extendedGamepad else { return }
//            print(gamepad)
////            gamepad.valueChangedHandler = self.handleGamepadInput
//        }
//        
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: nil) { note in
//            guard let controller = note.object as? GCController, let gamepad = controller.extendedGamepad else { return }
//            gamepad.valueChangedHandler = nil
//        }
//        
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCKeyboardDidConnect, object: nil, queue: nil) { note in
//            guard let keyboard = note.object as? GCKeyboard, let keyboardInput = keyboard.keyboardInput else { return }
//            print(keyboardInput)
////            keyboardInput.keyChangedHandler = self.handleKeyboardInput
//        }
//        
//        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCKeyboardDidDisconnect, object: nil, queue: nil) { note in
//            guard let keyboard = note.object as? GCKeyboard, let keyboardInput = keyboard.keyboardInput else { return }
//            keyboardInput.keyChangedHandler = nil
//        }
//        
//        // bind already connected controllers
//
//        if let keyboard = GCKeyboard.coalesced, let input = keyboard.keyboardInput {
//            input.keyChangedHandler = self.handleKeyboardInput
//        }
//        
//        for gamepad in GCController.controllers() {
//            if let gamepad = gamepad.extendedGamepad {
//                gamepad.valueChangedHandler = self.handleGamepadInput
//            }
//        }
//        
//        touchControlsDelegate?.valueChangedHandler = self.handleTouchInput
//    }
//
//    func stopListeningForInputs() {
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCControllerDidConnect, object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCKeyboardDidConnect, object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCKeyboardDidDisconnect, object: nil)
//
//        if let keyboard = GCKeyboard.coalesced {
//            keyboard.keyboardInput?.keyChangedHandler = nil
//        }
//        
//        for gamepad in GCController.controllers() {
//            if let gamepad = gamepad.extendedGamepad {
//                gamepad.valueChangedHandler = nil
//            }
//        }
//        
//        touchControlsDelegate?.valueChangedHandler = nil
//    }
//    
//    private func handleGamepadInput(gamepad: GCExtendedGamepad, _: GCControllerElement) {
//        var state: UInt32 = 0
//        
//        state |= GameInput.dpadUp.rawValue * UInt32(gamepad.dpad.up.isPressed)
//        state |= GameInput.dpadDown.rawValue * UInt32(gamepad.dpad.down.isPressed)
//        state |= GameInput.dpadLeft.rawValue * UInt32(gamepad.dpad.left.isPressed)
//        state |= GameInput.dpadRight.rawValue * UInt32(gamepad.dpad.right.isPressed)
//        
//        state |= GameInput.faceButtonRight.rawValue * UInt32(gamepad.buttonA.isPressed)
//        state |= GameInput.faceButtonDown.rawValue * UInt32(gamepad.buttonB.isPressed)
//
//        state |= GameInput.startButton.rawValue * UInt32(gamepad.buttonMenu.isPressed)
//        state |= GameInput.selectButton.rawValue * UInt32(gamepad.buttonOptions?.isPressed ?? false)
//        
//        self.core.playerSetInputs(player: 0, value: state)
//    }
//    
//    private func handleKeyboardInput(keyboard: GCKeyboardInput?, key: GCDeviceButtonInput?, keyCode: GCKeyCode, pressed: Bool) {
//        let input = switch keyCode {
//        case .keyZ:             GameInput.faceButtonRight
//        case .keyX:             GameInput.faceButtonDown
//        case .returnOrEnter:    GameInput.startButton
//        case .rightShift:       GameInput.selectButton
//        case .upArrow:          GameInput.dpadUp
//        case .downArrow:        GameInput.dpadDown
//        case .leftArrow:        GameInput.dpadLeft
//        case .rightArrow:       GameInput.dpadRight
//        default:                GameInput.none
//        }
//        
//        inputs[0] = pressed
//            ? inputs[0] | input.rawValue
//            : inputs[0] & ~input.rawValue
//        
//        self.core.playerSetInputs(player: 0, value: inputs[0])
//    }
//    
//    private func handleTouchInput(input: UInt32) {
//        self.core.playerSetInputs(player: 0, value: input)
//    }
}
