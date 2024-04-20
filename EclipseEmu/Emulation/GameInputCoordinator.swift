import Foundation
import GameController
import EclipseKit

protocol GameInputCoordinatorDelegate {
    func reorderControllers(players: inout [GameInputCoordinator.Player], maxPlayers: UInt8) async -> Void
}

struct GameInputCoordinator: ~Copyable {
    weak var coreCoordinator: GameCoreCoordinator?
    var delegate: GameInputCoordinatorDelegate?
    
    var maxPlayers: UInt8 = 0
    var players = [Player]()
    
    private var touchState: UInt32 = 0

    struct Player: Identifiable {
        var id = UUID()
        var state: UInt32 = 0
        var kind: ControllerKind
        
        enum ControllerKind {
            case touch(Box<TouchLayout>)
            case keyboard(Box<KeyboardBindings>, GCKeyboard)
            case gamepad(Box<[GamepadBinding]>, GCController)
        }
    }
    
    init(maxPlayers: UInt8) {
        self.maxPlayers = maxPlayers
    }
    
    mutating func playerConnected(kind: Player.ControllerKind) async {
        guard let delegate, let coreCoordinator else { return }
        
        let newPlayer = Player(kind: kind)
        
        self.players.append(newPlayer)
        await delegate.reorderControllers(players: &self.players, maxPlayers: self.maxPlayers)
        let index = self.players.firstIndex(where: { $0.id == newPlayer.id }) ?? -1
        
        // only report a new player if necessary
        if players.count < maxPlayers && index > -1 && index < maxPlayers {
            // FIXME: if the core rejects the new player, what should happen?
            let _ = await coreCoordinator.playerConnected(player: UInt8(index))
        }
    }
    
    mutating func playerDisconnected(id: UUID) async {
        guard let delegate, let coreCoordinator else { return }
        
        guard let index = self.players.firstIndex(where: { $0.id == id }) else { return }
        await delegate.reorderControllers(players: &self.players, maxPlayers: self.maxPlayers)
        
        if players.count < maxPlayers {
            await coreCoordinator.playerDisconnected(player: UInt8(index))
        }
    }
    
    // NOTE: Actually polling for touch controls is not practical, so we just store the touch state for the next poll
    mutating func touchControlsChanged(newState: UInt32) -> Void {
        self.touchState = newState
    }
    
    /// Loads the current state for each player their respective state field.
    mutating func poll() {
        for var player in self.players {
            switch player.kind {
            case .touch:
                player.state = self.touchState
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
                        player.state |= UInt32(inputs.buttons[binding.id]?.isPressed ?? false) * binding.input.rawValue
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
        case .touch(_):
            return "Touch"
        case .keyboard(_, let device):
            return device.vendorName ?? "Keyboard"
        case .gamepad(_, let device):
            return device.vendorName ?? "Controller"
        }
    }
}
