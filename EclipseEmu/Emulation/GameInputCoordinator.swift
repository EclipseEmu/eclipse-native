import Foundation
import Atomics
import GameController
import EclipseKit

struct GameInputPlayer {}

private struct GamepadInfo {
    var playerIndex: Int
    var bindings: [GamepadBinding]
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

    private var keyboardBindings: KeyboardBindings!
    private var gamepadBindings: [ObjectIdentifier: GamepadInfo] = [:]

    private let reorder: ReorderCallback

    private var controllerConnectObserver: Task<Void, Never>!
    private var controllerDisconnectObserver: Task<Void, Never>!
    private var keyboardConnectObserver: Task<Void, Never>!
    private var keyboardDisconnectObserver: Task<Void, Never>!

    init(maxPlayers: UInt8, reorder: @escaping ReorderCallback) {
        self.maxPlayerCount = maxPlayers
        self.reorder = reorder

        states = .init(repeating: .init(0), count: Int(maxPlayerCount))

        controllerConnectObserver = Task(operation: controllerDidConnect)
        controllerDisconnectObserver = Task(operation: controllerDidDisconnect)
        keyboardConnectObserver = Task(operation: keyboardDidConnect)
        keyboardDisconnectObserver = Task(operation: keyboardDidDisconnect)
    }

    func start() {
        self.running.store(true, ordering: .relaxed)
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

    // MARK: Connection Change Listeners

    nonisolated func controllerDidConnect() async {
        let stream = NotificationCenter.default.notifications(named: .GCControllerDidConnect)
        for await notification in stream {
            guard
                !Task.isCancelled,
                let device = notification.object as? GCController,
                let gamepad = device.extendedGamepad
            else { continue }

            let id = device.id
            let bindings = await self.loadGamepadBindings(for: id)
            await MainActor.run {
                self.gamepadBindings[id] = .init(playerIndex: 0, bindings: bindings)
            }

            gamepad.valueChangedHandler = self.handleGamepadInput
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

    nonisolated func keyboardDidConnect() async {
        let stream = NotificationCenter.default.notifications(named: .GCKeyboardDidConnect)
        for await notification in stream {
            guard
                !Task.isCancelled,
                let device = notification.object as? GCKeyboard,
                let keyboardInput = device.keyboardInput
            else { continue }

            await Task { @MainActor in
                if self.keyboardBindings == nil {
                    self.keyboardBindings = await self.loadKeyboardBindings()
                }
            }.value

            keyboardInput.keyChangedHandler = handleKeyboardInput
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

extension GameInputCoordinator {
    func loadGamepadBindings(for _: GCController.ID) async -> [GamepadBinding] {
        // FIXME: do proper binding loading
        return [
            .init(control: GCInputButtonA, kind: .button(.faceButtonRight)),
            .init(control: GCInputButtonB, kind: .button(.faceButtonDown)),
            .init(control: GCInputButtonMenu, kind: .button(.startButton)),
            .init(control: GCInputButtonOptions, kind: .button(.selectButton)),
            .init(control: GCInputLeftShoulder, kind: .button(.shoulderLeft)),
            .init(control: GCInputRightShoulder, kind: .button(.shoulderRight)),
            .init(
                control: GCInputDirectionPad,
                kind: .directionPad(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
            ),
            .init(
                control: GCInputLeftThumbstick,
                kind: .joystick(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
            )
        ]
    }

    func loadKeyboardBindings() async -> KeyboardBindings {
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
}
