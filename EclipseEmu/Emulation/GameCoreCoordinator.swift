import Foundation
import GameController
import QuartzCore
import EclipseKit
import simd

protocol GameCoreCoordinatorTouchControlsDelegate {
    var valueChangedHandler: ((UInt32) -> Void)? { get set }
}

class GameCoreCoordinator: NSObject, ObservableObject {
    enum Failure: Error {
        case failedToGetMetalDevice
        case failedToCreateFullscreenQuad
        case failedToCreatePipelineState
        case failedToCreateTheCommandQueue
        case failedToCreateSamplerState
    }
    
    @Published var width: CGFloat = 0.0
    @Published var height: CGFloat = 0.0
    @Published var isRunning: Bool = false
    
    let core: GameCore
    var inputs: [UInt32] = [0]
    var touchControlsDelegate: GameCoreCoordinatorTouchControlsDelegate?

    // rendering properties
    private var renderer: GameRenderer!
    var renderingSurface: CAMetalLayer!

    // frame timer properties
    private let desiredFrameRate: Double
    private var frameDuration: Double
    private(set) var rate: Double = 1.0
    private var frameTimerTask: Task<Void, Never>?
    
    private var useAdaptiveSync = true
    
    init(core: GameCore) throws {
        self.core = core
        
        core.setup()
        
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
        
        super.init()
    }
    
    deinit {
        self.stopListeningForInputs()
        core.stop()
        core.takedown()
    }
    
    func setupGameRendering() throws {}
    
    func start(gameUrl: URL) {
        guard self.core.start(url: gameUrl) else {
            print("failed to start game, L")
            return
        }
        self.play()
    }
    
    func stop() {
        self.pause()
        self.core.stop()
        self.stopListeningForInputs()
    }
    
    func play() {
        self.startListeningForInputs()
        self.core.play()
        self.startFrameTimer()
        self.isRunning = true
    }
    
    func pause() {
        self.core.pause()
        self.stopListeningForInputs()
        self.frameTimerTask?.cancel()
        self.frameTimerTask = nil
        self.isRunning = false
    }
    
    func renderFrame() {
        self.renderer.render(in: self.renderingSurface)
    }

    // MARK: Frame Timing

    func setFastForward(enabled: Bool) {
        let rate: Double = enabled ? 2 : 1
        self.rate = rate
        #if canImport(AppKit)
        self.renderingSurface.displaySyncEnabled = !enabled
        #endif
        self.frameDuration = (1.0 / desiredFrameRate) / rate
    }
    
    func startFrameTimer() {
        self.frameTimerTask?.cancel()
        self.frameTimerTask = Task(priority: .userInitiated) {
            // TODO: seperate refresh rate from core frame duration
            let refreshRateDouble: Double = 1.0 / 60.0
            let maxCatchupRate: ContinuousClock.Duration = .seconds(5 * refreshRateDouble)
            
            let initialTime: ContinuousClock.Instant = .now
            var time: ContinuousClock.Duration = .zero
            let frameDuration: ContinuousClock.Duration = .seconds(self.frameDuration)
            
            while !Task.isCancelled {
                let start: ContinuousClock.Instant = .now
                
                let expectedTime = start - initialTime
                time = max(time, expectedTime - maxCatchupRate)
                
                while time <= expectedTime {
                    let doRender = time + frameDuration >= expectedTime
                    time += frameDuration
                    self.core.executeFrame(processVideo: doRender)
                    if doRender {
                        self.renderFrame()
                    }
                }
                
                let now: ContinuousClock.Instant = .now
                let sleepTime = frameDuration - (now - start)
                if sleepTime > .zero {
                    try? await Task.sleep(until: now + sleepTime)
                } else {
                    await Task.yield()
                }
            }
        }
    }

    // MARK: Input handling

    func startListeningForInputs() {
        // listen for new connections
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidConnect, object: nil, queue: nil) { note in
            guard let controller = note.object as? GCController, let gamepad = controller.extendedGamepad else { return }
            gamepad.valueChangedHandler = self.handleGamepadInput
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCControllerDidDisconnect, object: nil, queue: nil) { note in
            guard let controller = note.object as? GCController, let gamepad = controller.extendedGamepad else { return }
            gamepad.valueChangedHandler = nil
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCKeyboardDidConnect, object: nil, queue: nil) { note in
            guard let keyboard = note.object as? GCKeyboard, let keyboardInput = keyboard.keyboardInput else { return }
            keyboardInput.keyChangedHandler = self.handleKeyboardInput
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.GCKeyboardDidDisconnect, object: nil, queue: nil) { note in
            guard let keyboard = note.object as? GCKeyboard, let keyboardInput = keyboard.keyboardInput else { return }
            keyboardInput.keyChangedHandler = nil
        }
        
        // bind already connected controllers

        if let keyboard = GCKeyboard.coalesced, let input = keyboard.keyboardInput {
            input.keyChangedHandler = self.handleKeyboardInput
        }
        
        for gamepad in GCController.controllers() {
            if let gamepad = gamepad.extendedGamepad {
                gamepad.valueChangedHandler = self.handleGamepadInput
            }
        }
        
        touchControlsDelegate?.valueChangedHandler = self.handleTouchInput
    }

    func stopListeningForInputs() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCKeyboardDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCKeyboardDidDisconnect, object: nil)

        if let keyboard = GCKeyboard.coalesced {
            keyboard.keyboardInput?.keyChangedHandler = nil
        }
        
        for gamepad in GCController.controllers() {
            if let gamepad = gamepad.extendedGamepad {
                gamepad.valueChangedHandler = nil
            }
        }
        
        touchControlsDelegate?.valueChangedHandler = nil
    }
    
    private func handleGamepadInput(gamepad: GCExtendedGamepad, _: GCControllerElement) {
        var state: UInt32 = 0
        state |= GameInput.dpadUp.rawValue * UInt32(gamepad.dpad.up.isPressed)
        state |= GameInput.dpadDown.rawValue * UInt32(gamepad.dpad.down.isPressed)
        state |= GameInput.dpadLeft.rawValue * UInt32(gamepad.dpad.left.isPressed)
        state |= GameInput.dpadRight.rawValue * UInt32(gamepad.dpad.right.isPressed)
        
        state |= GameInput.faceButtonRight.rawValue * UInt32(gamepad.buttonA.isPressed)
        state |= GameInput.faceButtonDown.rawValue * UInt32(gamepad.buttonB.isPressed)

        state |= GameInput.startButton.rawValue * UInt32(gamepad.buttonMenu.isPressed)
        state |= GameInput.selectButton.rawValue * UInt32(gamepad.buttonOptions?.isPressed ?? false)
        
        inputs[0] = state
        self.core.playerSetInputs(player: 0, value: state)
    }
    
    private func handleKeyboardInput(keyboard: GCKeyboardInput?, key: GCDeviceButtonInput?, keyCode: GCKeyCode, pressed: Bool) {
        let input = switch keyCode {
        case .keyZ:             GameInput.faceButtonRight
        case .keyX:             GameInput.faceButtonDown
        case .returnOrEnter:    GameInput.startButton
        case .rightShift:       GameInput.selectButton
        case .upArrow:          GameInput.dpadUp
        case .downArrow:        GameInput.dpadDown
        case .leftArrow:        GameInput.dpadLeft
        case .rightArrow:       GameInput.dpadRight
        default:                GameInput.none
        }
        
        inputs[0] = pressed
            ? inputs[0] | input.rawValue
            : inputs[0] & ~input.rawValue
        
        self.core.playerSetInputs(player: 0, value: inputs[0])
    }
    
    private func handleTouchInput(input: UInt32) {
        inputs[0] = input
        self.core.playerSetInputs(player: 0, value: inputs[0])
    }
}
