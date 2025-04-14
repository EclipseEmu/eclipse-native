import Foundation
import Atomics
import GameController
import EclipseKit

struct GameInputPlayer {}

private struct GamepadInfo {
    var playerIndex: Int
    let bindings: InputSourceControllerDescriptor.Bindings
}

@MainActor
final class GameInputCoordinator {
    typealias ReorderCallback = @MainActor (inout [GameInputPlayer], UInt8) async -> Void

    nonisolated let running: ManagedAtomic<Bool> = .init(false)
    nonisolated let maxPlayerCount: UInt8
    nonisolated let playerCount: ManagedAtomic<UInt8> = .init(1)

    nonisolated private let builtinPlayer: Int = .init(0)
    nonisolated let states: [ManagedAtomic<GameInput.RawValue>]
    var players: [GameInputPlayer] = []

    private var keyboardBindings: InputSourceKeyboardDescriptor.Bindings!
    private var gamepadBindings: [GCController.ID: GamepadInfo] = [:]

    private let game: ObjectBox<GameObject>
    private let system: GameSystem
    private let bindingsManager: ControlBindingsManager

    private var controllerConnectObserver: Task<Void, Never>!
    private var controllerDisconnectObserver: Task<Void, Never>!
    private var keyboardConnectObserver: Task<Void, Never>!
    private var keyboardDisconnectObserver: Task<Void, Never>!

    init(maxPlayers: UInt8, game: ObjectBox<GameObject>, system: GameSystem, bindingsManager: ControlBindingsManager) {
        self.maxPlayerCount = maxPlayers
        self.bindingsManager = bindingsManager
        self.game = game
        self.system = system

        states = .init(repeating: .init(0), count: Int(maxPlayerCount))

        controllerConnectObserver = Task(operation: controllerDidConnect)
        controllerDisconnectObserver = Task(operation: controllerDidDisconnect)
        keyboardConnectObserver = Task(operation: keyboardDidConnect)
        keyboardDisconnectObserver = Task(operation: keyboardDidDisconnect)
    }

    func start() async {
        self.running.store(true, ordering: .relaxed)
        for controller in GCController.controllers() {
            await registerController(device: controller)
        }
        if let keyboard = GCKeyboard.coalesced {
            await registerKeyboard(device: keyboard)
        }
    }

    func stop() {
        self.running.store(false, ordering: .relaxed)
    }

    // MARK: Binding listeners

    nonisolated func handleKeyboardInput(_: GCKeyboardInput, _: GCControllerButtonInput, keyCode: GCKeyCode, isActive: Bool) {
        MainActor.assumeIsolated {
            guard
                let input = keyboardBindings[keyCode],
                builtinPlayer > -1,
                builtinPlayer < Int8(self.maxPlayerCount)
            else { return }

            let state = states[builtinPlayer]
            _ = if isActive {
                state.bitwiseOrThenLoad(with: input.rawValue, ordering: .relaxed)
            } else {
                state.bitwiseAndThenLoad(with: ~input.rawValue, ordering: .relaxed)
            }
        }
    }

    nonisolated func handleGamepadInput(gamepad: GCExtendedGamepad, element _: GCControllerElement) {
        guard let id = gamepad.controller?.id else { return }
        let info = MainActor.assumeIsolated { self.gamepadBindings[id] }
        guard let info, info.playerIndex > -1, info.playerIndex < Int8(maxPlayerCount) else { return }

        var state: UInt32 = 0
        for binding in info.bindings {
            switch binding.input {
            case .button(let input):
                state |= input.rawValue * UInt32(gamepad.buttons[binding.key]?.isPressed ?? false)
            case .directionPad(up: let up, down: let down, left: let left, right: let right):
                let dpad = gamepad.dpad
                state |= (up.rawValue * UInt32(dpad.up.isPressed)) |
                (down.rawValue * UInt32(dpad.down.isPressed)) |
                (left.rawValue * UInt32(dpad.left.isPressed)) |
                (right.rawValue * UInt32(dpad.right.isPressed))
            case .joystick(up: let up, down: let down, left: let left, right: let right):
                guard let dpad = gamepad.dpads[binding.key] else { return }
                // FIXME: make the deadzone configurable
                state |= (up.rawValue * UInt32(dpad.yAxis.value > 0.25)) |
                (down.rawValue * UInt32(dpad.yAxis.value < -0.25)) |
                (left.rawValue * UInt32(dpad.xAxis.value < -0.25)) |
                (right.rawValue * UInt32(dpad.xAxis.value > 0.25))
            default:
                break
            }
        }
        self.states[info.playerIndex].store(state, ordering: .relaxed)
    }

#if os(iOS)
    func handleTouchInput(newState: UInt32) {
        guard
            builtinPlayer > -1,
            builtinPlayer < Int8(maxPlayerCount)
        else { return }
        self.states[builtinPlayer].store(newState, ordering: .relaxed)
    }
#endif

    nonisolated func registerController(device: GCController) async {
        guard let gamepad = device.extendedGamepad else { return }

        let id = device.id
        let descriptor = device.inputSourceDescriptor
        await MainActor.run {
            let bindings = bindingsManager.load(for: descriptor, game: game, system: system)
            self.gamepadBindings[id] = .init(playerIndex: 0, bindings: bindings)
        }

        gamepad.valueChangedHandler = self.handleGamepadInput
    }

    nonisolated func registerKeyboard(device: GCKeyboard) async {
        guard let keyboard = device.keyboardInput else { return }

        await MainActor.run {
            if self.keyboardBindings == nil {
                self.keyboardBindings = bindingsManager.load(
                    for: GCKeyboard.inputSourceDescriptor,
                    game: game,
                    system: system
                )
            }
        }

        keyboard.keyChangedHandler = handleKeyboardInput
    }

    // MARK: Connection Change Listeners

    nonisolated func controllerDidConnect() async {
        let stream = NotificationCenter.default.notifications(named: .GCControllerDidConnect)
        for await notification in stream {
            guard
                !Task.isCancelled,
                let device = notification.object as? GCController
            else { continue }
            await registerController(device: device)
        }
    }

    nonisolated func keyboardDidConnect() async {
        let stream = NotificationCenter.default.notifications(named: .GCKeyboardDidConnect)
        for await notification in stream {
            guard
                !Task.isCancelled,
                let device = notification.object as? GCKeyboard
            else { continue }
            await registerKeyboard(device: device)
        }
    }

    nonisolated func controllerDidDisconnect() async {
        let stream = NotificationCenter.default.notifications(named: .GCControllerDidDisconnect)
        for await notification in stream {
            guard
                !Task.isCancelled,
                let device = notification.object as? GCController,
                let gamepad = device.extendedGamepad
            else { continue }

            gamepad.valueChangedHandler = nil
        }
    }

    nonisolated func keyboardDidDisconnect() async {
        let stream = NotificationCenter.default.notifications(named: .GCKeyboardDidDisconnect)
        for await notification in stream {
            guard
                !Task.isCancelled,
                let device = notification.object as? GCKeyboard,
                let keyboardInput = device.keyboardInput
            else { continue }

            keyboardInput.keyChangedHandler = nil
        }
    }
}
