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

//final class GameInputCoordinatorOld {
//    typealias ReorderControllersCallback = (inout [GameInputCoordinator.Player], UInt8) async -> Void
//    
//    struct Player: Identifiable {
//        var id = UUID()
//        var state: UInt32 = 0
//        var kind: ControllerKind
//        
//        enum ControllerKind: Equatable {
//            #if os(iOS)
//            case touch
//            #endif
//            case keyboard(Box<KeyboardBindings>)
//            case gamepad(ObjectIdentifier, Box<[GamepadBinding]>)
//            
//            static func ==(lhs: GameInputCoordinator.Player.ControllerKind, rhs: GameInputCoordinator.Player.ControllerKind) -> Bool {
//                switch (lhs, rhs) {
//                #if os(iOS)
//                case (.touch, .touch):
//                    return true
//                #endif
//                case (.keyboard(_), .keyboard(_)):
//                    return true
//                case (.gamepad(let lhsId, _), .gamepad(let rhsId, _)):
//                    return lhsId == rhsId
//                default:
//                    return false
//                }
//            }
//        }
//    }
//
//    // these two properties are used in comparisons where the bindings don't actually matter
//    static let throwawayKeyboardBindings = Box<KeyboardBindings>([
//        .keyZ:.faceButtonDown,
//        .keyX:.faceButtonRight,
//        .keyA:.shoulderLeft,
//        .keyS:.shoulderRight,
//        .upArrow:.dpadUp,
//        .downArrow:.dpadDown,
//        .leftArrow:.dpadLeft,
//        .rightArrow:.dpadRight,
//        .returnOrEnter:.startButton,
//        .rightShift:.selectButton
//    ])
//    static let throwawayGamepadBindings = Box<[GamepadBinding]>([
//        .init(kind: .button, id: GCInputButtonA, direction: .negative, deadZone: 0, input: .faceButtonRight),
//        .init(kind: .button, id: GCInputButtonB, direction: .negative, deadZone: 0, input: .faceButtonDown),
//        .init(kind: .button, id: GCInputButtonMenu, direction: .negative, deadZone: 0, input: .startButton),
//        .init(kind: .button, id: GCInputButtonOptions, direction: .negative, deadZone: 0, input: .selectButton),
//    ])
//    
//    weak var coreCoordinator: GameCoreCoordinator?
//    var reorderPlayers: ReorderControllersCallback
//    
//    var maxPlayers: UInt8 = 0
//    var players = [Player]()
//    
//    private var controllerConnectObserver: Any?
//    private var controllerDisconnectObserver: Any?
//    private var keyboardConnectObserver: Any?
//    private var keyboardDisconnectObserver: Any?
//    #if os(iOS)
//    weak var touchControls: TouchControlsController? {
//        didSet {
//            if oldValue == nil && touchControls != nil {
//                Task {
//                    await self.playerConnected(kind: .touch)
//                }
//            } else if oldValue != nil && touchControls == nil {
//                guard let player = self.getPlayer(kind: .touch) else { return }
//                Task {
//                    await self.playerDisconnected(id: player.id)
//                }
//            }
//        }
//    }
//    #endif
//
//    init(maxPlayers: UInt8, reorderPlayers: @escaping ReorderControllersCallback) {
//        self.maxPlayers = maxPlayers
//        self.reorderPlayers = reorderPlayers
//    }
//    
//    deinit {
//        self.stop()
//    }
//    
//    // MARK: Bindings loading
//    
//    private func loadGamepadBindings(for controller: GCController) async -> [GamepadBinding] {
//        // FIXME: do proper binding loading
//        return Self.throwawayGamepadBindings.value
//    }
//    
//    private func loadKeyboardBindings(for controller: GCKeyboard) async -> KeyboardBindings {
//        // FIXME: do proper binding loading
//        return Self.throwawayKeyboardBindings.value
//    }
//
//    // MARK: Connection management
//    
//    private func hasPlayer(kind: Player.ControllerKind) -> Bool {
//        return self.players.contains(where: { $0.kind == kind })
//    }
//    
//    private func getPlayer(kind: Player.ControllerKind) -> Player? {
//        return self.players.first(where: { $0.kind == kind })
//    }
//
//    func start() async {
//        if self.keyboardConnectObserver == nil {
//            self.keyboardConnectObserver = NotificationCenter.default.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: nil, using: { notification in
//                guard 
//                    let keyboard = notification.object as? GCKeyboard,
//                    keyboard.keyboardInput != nil
//                else { return }
//                
//                Task {
//                    let bindings = await self.loadKeyboardBindings(for: keyboard)
//                    await self.playerConnected(kind: .keyboard(Box(bindings)))
//                }
//            })
//        }
//        
//        if self.controllerConnectObserver == nil {
//            self.controllerConnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil, using: { notification in
//                print("kb connect?")
//                guard
//                    let controller = notification.object as? GCController,
//                    controller.extendedGamepad != nil
//                else { return }
//                
//                print("hi?")
//                
//                Task {
//                    let bindings = await self.loadGamepadBindings(for: controller)
//                    await self.playerConnected(kind: .gamepad(controller.id, Box(bindings)))
//                }
//            })
//        }
//        
//        if self.keyboardDisconnectObserver == nil {
//            self.keyboardDisconnectObserver = NotificationCenter.default.addObserver(forName: .GCKeyboardDidDisconnect, object: nil, queue: nil, using: { notification in
//                guard
//                    let keyboard = notification.object as? GCKeyboard,
//                    let player = self.getPlayer(kind: .keyboard(Self.throwawayKeyboardBindings))
//                else { return }
//                
//                Task {
//                    await self.playerDisconnected(id: player.id)
//                }
//            })
//        }
//
//        if self.controllerDisconnectObserver == nil {
//            self.controllerDisconnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil, using: { notification in
//                guard 
//                    let controller = notification.object as? GCController,
//                    let player = self.getPlayer(kind: .gamepad(controller.id, Self.throwawayGamepadBindings))
//                else { return }
//                
//                Task {
//                    await self.playerDisconnected(id: player.id)
//                }
//            })
//        }
//        
//        // FIXME: make these run concurrently, there's no real reason they should be ordered
//        
//        // Get currently connected controllers
////        let countBefore = self.players.count
////        for device in GCController.controllers() {
////            guard device.extendedGamepad != nil else { continue }
////            let bindings = await self.loadGamepadBindings(for: device)
////            let kind = Player.ControllerKind.gamepad(device.id, Box(bindings))
////            if !self.hasPlayer(kind: kind) {
////                self.players.append(.init(kind: kind))
////            }
////        }
////        
////        // Get the currently connected keyboard
////        if let device = GCKeyboard.coalesced {
////            let bindings = await self.loadKeyboardBindings(for: device)
////            let kind = Player.ControllerKind.keyboard(Box(bindings))
////            print("hi?")
////            if !self.hasPlayer(kind: kind) {
////                self.players.append(.init(kind: kind))
////            }
////        }
////        
//        // Notify the core, if necessary
////        let countAfter = self.players.count
////        let newlyAddedCount = min(countAfter - countBefore, Int(maxPlayers) - countAfter)
////        if let coreCoordinator, newlyAddedCount > 0 {
////            for index in 0..<newlyAddedCount {
////                let _ = await coreCoordinator.playerConnected(player: UInt8(index))
////            }
////        }
//    }
//    
//    func stop() {
//        if let controllerConnectObserver {
//            NotificationCenter.default.removeObserver(controllerConnectObserver)
//        }
//        if let controllerDisconnectObserver {
//            NotificationCenter.default.removeObserver(controllerDisconnectObserver)
//        }
//        if let keyboardConnectObserver {
//            NotificationCenter.default.removeObserver(keyboardConnectObserver)
//        }
//        if let keyboardDisconnectObserver {
//            NotificationCenter.default.removeObserver(keyboardDisconnectObserver)
//        }
//    }
//
//    func playerConnected(kind: Player.ControllerKind) async {
//        guard let coreCoordinator else { return }
//        
//        let newPlayer = Player(kind: kind)
//        
//        self.players.append(newPlayer)
//        if self.players.count > 1 {
//            await self.reorderPlayers(&self.players, self.maxPlayers)
//        }
//        let index = self.players.firstIndex(where: { $0.id == newPlayer.id }) ?? -1
//
//        // only report a new player if necessary
//        if players.count < maxPlayers && index > -1 && index < maxPlayers {
//            // FIXME: if the core rejects the new player, what should happen?
//            let _ = await coreCoordinator.playerConnected(player: UInt8(index))
//        }
//    }
//    
//    func playerDisconnected(id: UUID) async {
//        guard let coreCoordinator else { return }
//        
//        guard let index = self.players.firstIndex(where: { $0.id == id }) else { return }
//        await self.reorderPlayers(&self.players, self.maxPlayers)
//
//        if players.count < maxPlayers {
//            await coreCoordinator.playerDisconnected(player: UInt8(index))
//        }
//    }
//    
//    // MARK: Input handling
//    
//    func handleGamepad() {}
//    
//    /// Loads the current state for each player their respective state field.
////    func poll() {
////        for var player in self.players {
////            switch player.kind {
////            #if os(iOS)
////            case .touch:
////                player.state = self.touchControls?.state ?? 0
////            #endif
////            case .keyboard(let bindings, let device):
////                guard let inputs = GCKeyboard.coalesced else { continue }
////                player.state = 0
////                for (keyCode, input) in bindings.value {
////                    // FIXME: is inputs.button(forKeyCode:) practical for polling? or should the GCControllerButtonInput be cached?
////                    player.state |= input.rawValue * UInt32(inputs.keyboardInput?.button(forKeyCode: keyCode)?.isPressed ?? false)
////                }
////                if player.state != 0 {
////                    print("hi??")
////                }
////            case .gamepad(let bindings, let device):
////                guard let inputs = device.extendedGamepad else { continue }
////                player.state = 0
////                for binding in bindings.value {
////                    switch binding.kind {
////                    case .button:
////                        player.state |= binding.input.rawValue * UInt32(inputs.buttons[binding.id]?.isPressed ?? false)
////                    case .axis:
////                        let expected = Float32(binding.direction.rawValue) - binding.deadZone
////                        let value = inputs.axes[binding.id]?.value ?? 0
////                        player.state |= binding.input.rawValue * UInt32((binding.direction == .negative && value <= expected) || (binding.direction == .positive && value >= expected))
////                    }
////                }
////            }
////        }
////    }
//}

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
