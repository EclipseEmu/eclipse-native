import Foundation
import GameController

protocol GameInputCoordinatorDelegate {
    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async -> Void
}

final class GameInputCoordinator {
    typealias ReorderControllersCallback = (inout [Player], UInt8) async -> Void
    
    struct Player: Identifiable {
        var id = UUID()
        var state: UInt32 = 0
        var kind: Kind
        var gamepadId: ObjectIdentifier?
        
        enum Kind: UInt8, RawRepresentable {
            case builtin = 0
            case controller = 1
        }
    }
    
    struct GamepadInfo {
        var playerIndex: Int
        var bindings: [GamepadBinding]
    }
    
    weak var coreCoordinator: GameCoreCoordinator?
    var reorderPlayersCallback: ReorderControllersCallback
    
    let maxPlayers: UInt8
    private let builtinPlayer: Int = 0
    private(set) var players: [Player] = [
        .init(kind: .builtin)
    ]
    
    private var keyboardBindings: KeyboardBindings!
    private var gamepadBindings: [ObjectIdentifier: GamepadInfo] = [:]
    
    init(maxPlayers: UInt8, reorderPlayers: @escaping ReorderControllersCallback) {
        self.maxPlayers = maxPlayers
        self.reorderPlayersCallback = reorderPlayers
    }
    
    private func loadGamepadBindings(for controller: GCController) async -> [GamepadBinding] {
        // FIXME: do proper binding loading
        return [
            .init(control: GCInputButtonA, kind: .button(.faceButtonRight)),
            .init(control: GCInputButtonB, kind: .button(.faceButtonDown)),
            .init(control: GCInputButtonMenu, kind: .button(.startButton)),
            .init(control: GCInputButtonOptions, kind: .button(.selectButton)),
            .init(control: GCInputLeftShoulder, kind: .button(.shoulderLeft)),
            .init(control: GCInputRightShoulder, kind: .button(.shoulderRight)),
            .init(control: GCInputDirectionPad, kind: .directionPad(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)),
            .init(control: GCInputLeftThumbstick, kind: .joystick(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)),
        ]
    }
    
    private func loadKeyboardBindings() async -> KeyboardBindings {
        // FIXME: do proper binding loading
        return [
            .keyZ: .faceButtonDown,
            .keyX: .faceButtonRight,
            .keyA: .shoulderLeft,
            .keyS: .shoulderRight,
            .upArrow: .dpadUp,
            .downArrow: .dpadDown,
            .leftArrow: .dpadLeft,
            .rightArrow: .dpadRight,
            .returnOrEnter: .startButton,
            .rightShift: .selectButton
        ]
    }
    
    func start() async {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil) { [weak self] note in
            guard
                let self,
                let controller = note.object as? GCController,
                let gamepad = controller.extendedGamepad
            else { return }
            
            Task {
                let bindings = await self.loadGamepadBindings(for: controller)
                
                self.gamepadBindings[controller.id] = .init(playerIndex: 0, bindings: bindings)
                gamepad.valueChangedHandler = self.handleGamepadInput
            }
        }
        
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil) { note in
            guard 
                let controller = note.object as? GCController,
                let gamepad = controller.extendedGamepad 
            else { return }
            
            gamepad.valueChangedHandler = nil
        }
        
        NotificationCenter.default.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: nil) { [weak self] note in
            guard 
                let self,
                let keyboard = note.object as? GCKeyboard,
                let keyboardInput = keyboard.keyboardInput
            else { return }
            
            Task {
                if self.keyboardBindings == nil {
                    self.keyboardBindings = await self.loadKeyboardBindings()
                }
                keyboardInput.keyChangedHandler = self.handleKeyboardInput
            }
        }
        
        NotificationCenter.default.addObserver(forName: .GCKeyboardDidDisconnect, object: nil, queue: nil) { note in
            guard 
                let keyboard = note.object as? GCKeyboard,
                let keyboardInput = keyboard.keyboardInput 
            else { return }
            
            keyboardInput.keyChangedHandler = nil
        }
        
        if let keyboard = GCKeyboard.coalesced, let input = keyboard.keyboardInput {
            if self.keyboardBindings == nil {
                self.keyboardBindings = await self.loadKeyboardBindings()
            }
            input.keyChangedHandler = self.handleKeyboardInput
        }
        
        for gamepad in GCController.controllers() {
            if let extended = gamepad.extendedGamepad {
                let bindings = await self.loadGamepadBindings(for: gamepad)
                self.gamepadBindings[gamepad.id] = .init(playerIndex: 0, bindings: bindings)
                extended.valueChangedHandler = self.handleGamepadInput
            }
        }
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCControllerDidDisconnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCKeyboardDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: .GCKeyboardDidDisconnect, object: nil)

        if let keyboard = GCKeyboard.coalesced {
            keyboard.keyboardInput?.keyChangedHandler = nil
        }
        
        for gamepad in GCController.controllers() {
            if let gamepad = gamepad.extendedGamepad {
                gamepad.valueChangedHandler = nil
            }
        }
    }
    
    func handleKeyboardInput(_: GCKeyboardInput, _: GCControllerButtonInput, keyCode: GCKeyCode, isActive: Bool) {
        guard 
            let input = self.keyboardBindings[keyCode],
            self.builtinPlayer > -1 && self.builtinPlayer < Int8(self.maxPlayers)
        else { return }
        
        let state = self.players[self.builtinPlayer].state
        self.players[self.builtinPlayer].state = isActive
            ? state | input.rawValue
            : state & (~input.rawValue)
    }
    
    func handleGamepadInput(gamepad: GCExtendedGamepad, element: GCControllerElement) {
        guard
            let id = gamepad.controller?.id,
            let info = self.gamepadBindings[id],
            info.playerIndex > -1 && info.playerIndex < Int8(self.maxPlayers)
        else { return }
        
        var state: UInt32 = 0
        for binding in info.bindings {
            switch binding.kind {
            case .button(let input):
                state |= input.rawValue * UInt32(gamepad.buttons[binding.control]?.isPressed ?? false)
            case .directionPad(up: let up, down: let down, left: let left, right: let right):
                let dpad = gamepad.dpad
                state |= (up.rawValue * UInt32(dpad.up.isPressed)) |
                    (down.rawValue * UInt32(dpad.down.isPressed)) |
                    (left.rawValue * UInt32(dpad.left.isPressed)) |
                    (right.rawValue * UInt32(dpad.right.isPressed))
            case .joystick(up: let up, down: let down, left: let left, right: let right):
                guard let dpad = gamepad.dpads[binding.control] else { return }
                // FIXME: make the deadzone configurable
                state |= (up.rawValue * UInt32(dpad.yAxis.value > 0.25)) |
                    (down.rawValue * UInt32(dpad.yAxis.value < -0.25)) |
                    (left.rawValue * UInt32(dpad.xAxis.value < -0.25)) |
                    (right.rawValue * UInt32(dpad.xAxis.value > 0.25))
            default:
                print("unhandled")
            }
        }
        self.players[info.playerIndex].state = state
    }
    
    #if os(iOS)
    func handleTouchInput(newState: UInt32) {
        guard self.builtinPlayer > -1 && self.builtinPlayer < Int8(self.maxPlayers) else { return }
        self.players[self.builtinPlayer].state = newState
    }
    #endif
}

// MARK: UI related helpers for player listings

extension GameInputCoordinator.Player {
    var displayName: String {
        switch self.kind {
        case .builtin:
            return "Touch/Keyboard"
        case .controller:
            return "Controller"
//            return GCController.controllers().first(where: { $0.id == id })?.vendorName ?? "Controller"
        }
    }
    
    var sfSymbol: String {
        switch self.kind {
        case .builtin:
            return "keyboard"
        case .controller:
//            switch GCController.controllers().first(where: { $0.id == id })?.productCategory {
//            case GCProductCategoryXboxOne:
//                return "xbox.logo"
//            case GCProductCategoryDualShock4, GCProductCategoryDualSense:
//                return "playstation.logo"
//            default:
            return "gamecontroller"
//            }
        }
    }
}
