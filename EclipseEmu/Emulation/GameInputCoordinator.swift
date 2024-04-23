import Foundation
import GameController

protocol GameInputCoordinatorDelegate {
    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async -> Void
}

final class GameInputCoordinator {
    typealias ReorderControllersCallback = (inout [GameInputCoordinator.Player], UInt8) async -> Void
    
    struct Player: Identifiable {
        var id = UUID()
        var state: UInt32 = 0
        var kind: ControllerKind
        
        enum ControllerKind: Equatable {
            #if os(iOS)
            case touch
            #endif
            case keyboard(Box<KeyboardBindings>, GCKeyboard)
            case gamepad(Box<[GamepadBinding]>, GCController)
            
            static func ==(lhs: GameInputCoordinator.Player.ControllerKind, rhs: GameInputCoordinator.Player.ControllerKind) -> Bool {
                switch (lhs, rhs) {
                #if os(iOS)
                case (.touch, .touch):
                    return true
                #endif
                case (.gamepad(_, let lhsDevice), .gamepad(_, let rhsDevice)):
                    return lhsDevice.id == rhsDevice.id
                case (.keyboard(_, let lhsDevice), .keyboard(_, let rhsDevice)):
                    return lhsDevice == rhsDevice
                default:
                    return false
                }
            }
        }
    }

    // these two properties are used in comparisons where the bindings don't actually matter
    static let throwawayKeyboardBindings = Box<KeyboardBindings>([:])
    static let throwawayGamepadBindings = Box<[GamepadBinding]>([])
    
    weak var coreCoordinator: GameCoreCoordinator?
    var reorderPlayers: ReorderControllersCallback
    
    var maxPlayers: UInt8 = 0
    var players = [Player]()
    
    private var controllerConnectObserver: Any?
    private var controllerDisconnectObserver: Any?
    private var keyboardConnectObserver: Any?
    private var keyboardDisconnectObserver: Any?
    #if os(iOS)
    weak var touchControls: TouchControlsController? {
        didSet {
            if oldValue == nil && touchControls != nil {
                Task {
                    await self.playerConnected(kind: .touch)
                }
            } else if oldValue != nil && touchControls == nil {
                guard let player = self.getPlayer(kind: .touch) else { return }
                Task {
                    await self.playerDisconnected(id: player.id)
                }
            }
        }
    }
    #endif

    init(maxPlayers: UInt8, reorderPlayers: @escaping ReorderControllersCallback) {
        self.maxPlayers = maxPlayers
        self.reorderPlayers = reorderPlayers
    }
    
    deinit {
        self.stop()
    }
    
    // MARK: Bindings loading
    
    private func loadGamepadBindings(for controller: GCController) async -> [GamepadBinding] {
        // FIXME: do proper binding loading
        return Self.throwawayGamepadBindings.value
    }
    
    private func loadKeyboardBindings(for controller: GCKeyboard) async -> KeyboardBindings {
        // FIXME: do proper binding loading
        return Self.throwawayKeyboardBindings.value
    }

    // MARK: Connection management
    
    private func hasPlayer(kind: Player.ControllerKind) -> Bool {
        return self.players.contains(where: { $0.kind == kind })
    }
    
    private func getPlayer(kind: Player.ControllerKind) -> Player? {
        return self.players.first(where: { $0.kind == kind })
    }

    func start() async {
        if self.keyboardConnectObserver == nil {
            self.keyboardConnectObserver = NotificationCenter.default.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: nil, using: { notification in
                guard 
                    let keyboard = notification.object as? GCKeyboard,
                    keyboard.keyboardInput != nil
                else { return }
                
                Task {
                    let bindings = await self.loadKeyboardBindings(for: keyboard)
                    await self.playerConnected(kind: .keyboard(Box(bindings), keyboard))
                }
            })
        }
        
        if self.controllerConnectObserver == nil {
            self.controllerConnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: nil, using: { notification in
                guard 
                    let controller = notification.object as? GCController,
                    controller.extendedGamepad != nil
                else { return }
                
                Task {
                    let bindings = await self.loadGamepadBindings(for: controller)
                    await self.playerConnected(kind: .gamepad(Box(bindings), controller))
                }
            })
        }
        
        if self.keyboardDisconnectObserver == nil {
            self.keyboardDisconnectObserver = NotificationCenter.default.addObserver(forName: .GCKeyboardDidDisconnect, object: nil, queue: nil, using: { notification in
                guard
                    let keyboard = notification.object as? GCKeyboard,
                    let player = self.getPlayer(kind: .keyboard(Self.throwawayKeyboardBindings, keyboard))
                else { return }
                
                Task {
                    await self.playerDisconnected(id: player.id)
                }
            })
        }

        if self.controllerDisconnectObserver == nil {
            self.controllerDisconnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: nil, using: { notification in
                guard 
                    let controller = notification.object as? GCController,
                    let player = self.getPlayer(kind: .gamepad(Self.throwawayGamepadBindings, controller))
                else { return }
                
                Task {
                    await self.playerDisconnected(id: player.id)
                }
            })
        }
        
        // Get currently connected controllers
        let countBefore = self.players.count
        for device in GCController.controllers() {
            guard device.extendedGamepad != nil else { continue }
            let bindings = await self.loadGamepadBindings(for: device)
            let kind = Player.ControllerKind.gamepad(Box(bindings), device)
            if !self.hasPlayer(kind: kind) {
                self.players.append(.init(kind: kind))
            }
        }
        
        // Get the currently connected keyboard
        if let device = GCKeyboard.coalesced {
            let bindings = await self.loadKeyboardBindings(for: device)
            let kind = Player.ControllerKind.keyboard(Box(bindings), device)
            if !self.hasPlayer(kind: kind) {
                self.players.append(.init(kind: kind))
            }
        }
        
        // Notify the core, if necessary
        let countAfter = self.players.count
        let newlyAddedCount = min(countAfter - countBefore, Int(maxPlayers) - countAfter)
        if let coreCoordinator, newlyAddedCount > 0 {
            for index in 0..<newlyAddedCount {
                let _ = await coreCoordinator.playerConnected(player: UInt8(index))
            }
        }
    }
    
    func stop() {
        if let controllerConnectObserver {
            NotificationCenter.default.removeObserver(controllerConnectObserver)
        }
        if let controllerDisconnectObserver {
            NotificationCenter.default.removeObserver(controllerDisconnectObserver)
        }
        if let keyboardConnectObserver {
            NotificationCenter.default.removeObserver(keyboardConnectObserver)
        }
        if let keyboardDisconnectObserver {
            NotificationCenter.default.removeObserver(keyboardDisconnectObserver)
        }
    }

    func playerConnected(kind: Player.ControllerKind) async {
        guard let coreCoordinator else { return }
        
        let newPlayer = Player(kind: kind)
        
        self.players.append(newPlayer)
        if self.players.count > 1 {
            await self.reorderPlayers(&self.players, self.maxPlayers)
        }
        let index = self.players.firstIndex(where: { $0.id == newPlayer.id }) ?? -1

        // only report a new player if necessary
        if players.count < maxPlayers && index > -1 && index < maxPlayers {
            // FIXME: if the core rejects the new player, what should happen?
            let _ = await coreCoordinator.playerConnected(player: UInt8(index))
        }
    }
    
    func playerDisconnected(id: UUID) async {
        guard let coreCoordinator else { return }
        
        guard let index = self.players.firstIndex(where: { $0.id == id }) else { return }
        await self.reorderPlayers(&self.players, self.maxPlayers)

        if players.count < maxPlayers {
            await coreCoordinator.playerDisconnected(player: UInt8(index))
        }
    }
    
    // MARK: Input handling
    
    /// Loads the current state for each player their respective state field.
    func poll() {
        for var player in self.players {
            switch player.kind {
            #if os(iOS)
            case .touch:
                player.state = self.touchControls?.state ?? 0
            #endif
            case .keyboard(let bindings, let device):
                guard let inputs = device.keyboardInput else { continue }
                player.state = 0
                for (keyCode, input) in bindings.value {
                    // FIXME: is inputs.button(forKeyCode:) practical for polling? or should the GCControllerButtonInput be cached?
                    player.state |= input.rawValue * UInt32(inputs.button(forKeyCode: keyCode)?.isPressed ?? false)
                }
            case .gamepad(let bindings, let device):
                guard let inputs = device.extendedGamepad else { continue }
                player.state = 0
                for binding in bindings.value {
                    switch binding.kind {
                    case .button:
                        player.state |= binding.input.rawValue * UInt32(inputs.buttons[binding.id]?.isPressed ?? false)
                    case .axis:
                        let expected = Float32(binding.direction.rawValue) - binding.deadZone
                        let value = inputs.axes[binding.id]?.value ?? 0
                        player.state |= binding.input.rawValue * UInt32((binding.direction == .negative && value <= expected) || (binding.direction == .positive && value >= expected))
                    }
                }
            }
        }
    }
}

extension GameInputCoordinator.Player {
    var displayName: String {
        switch self.kind {
        #if os(iOS)
        case .touch:
            return "Touch"
        #endif
        case .keyboard(_, let device):
            return device.vendorName ?? "Keyboard"
        case .gamepad(_, let device):
            return device.vendorName ?? "Controller"
        }
    }
    
    var sfSymbol: String {
        switch self.kind {
        #if os(iOS)
        case .touch:
            return "hand.draw"
        #endif
        case .keyboard(_, _):
            return "keyboard"
        case .gamepad(_, let device):
            switch device.productCategory {
            case GCProductCategoryXboxOne:
                return "xbox.logo"
            case GCProductCategoryDualShock4, GCProductCategoryDualSense:
                return "playstation.logo"
            default:
                return "gamecontroller"
            }
        }
    }
}
