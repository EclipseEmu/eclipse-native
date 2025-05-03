import GameController
import EclipseKit

enum InputSourceControllerInput: Codable {
    case button(GameInput)
    case directionPad(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
    case joystick(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
    case gyro(x: GameInput, y: GameInput, z: GameInput)
    case touchPad(x: GameInput, y: GameInput)
}

struct InputSourceControllerBinding: Codable, Sendable {
    let key: String
    let input: InputSourceControllerInput
}

typealias InputSourceControllerBindings = [InputSourceControllerBinding]

enum InputSourceControllerVersion: Int16, RawRepresentable {
    case v1 = 1
}

struct InputSourceControllerDescriptor: InputSourceDescriptorProtocol {
    typealias Bindings = InputSourceControllerBindings

    let kind: ControlsInputSourceKind = .controller
    let id: String?

    static func defaults(for system: GameSystem) -> InputSourceControllerBindings {
        switch system {
        case .gb, .gbc, .nes:
            [
                .init(key: GCInputButtonA, input: .button(.faceButtonRight)),
                .init(key: GCInputButtonB, input: .button(.faceButtonDown)),
                .init(key: GCInputButtonMenu, input: .button(.startButton)),
                .init(key: GCInputButtonOptions, input: .button(.selectButton)),
                .init(
                    key: GCInputDirectionPad,
                    input: .directionPad(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
                ),
                .init(
                    key: GCInputLeftThumbstick,
                    input: .joystick(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
                )
            ]
        case .gba:
            [
                .init(key: GCInputButtonA, input: .button(.faceButtonRight)),
                .init(key: GCInputButtonB, input: .button(.faceButtonDown)),
                .init(key: GCInputButtonMenu, input: .button(.startButton)),
                .init(key: GCInputButtonOptions, input: .button(.selectButton)),
                .init(key: GCInputLeftShoulder, input: .button(.shoulderLeft)),
                .init(key: GCInputRightShoulder, input: .button(.shoulderRight)),
                .init(
                    key: GCInputDirectionPad,
                    input: .directionPad(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
                ),
                .init(
                    key: GCInputLeftThumbstick,
                    input: .joystick(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
                )
            ]
        case .snes:
            [
                .init(key: GCInputButtonA, input: .button(.faceButtonRight)),
                .init(key: GCInputButtonB, input: .button(.faceButtonDown)),
                .init(key: GCInputButtonX, input: .button(.faceButtonUp)),
                .init(key: GCInputButtonY, input: .button(.faceButtonLeft)),
                .init(key: GCInputButtonMenu, input: .button(.startButton)),
                .init(key: GCInputButtonOptions, input: .button(.selectButton)),
                .init(key: GCInputLeftShoulder, input: .button(.shoulderLeft)),
                .init(key: GCInputRightShoulder, input: .button(.shoulderRight)),
                .init(
                    key: GCInputDirectionPad,
                    input: .directionPad(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
                ),
                .init(
                    key: GCInputLeftThumbstick,
                    input: .joystick(up: .dpadUp, down: .dpadDown, left: .dpadLeft, right: .dpadRight)
                )
            ]
        default: []
        }
    }

    func encode(_ bindings: InputSourceControllerBindings, encoder: JSONEncoder) throws -> ControlsConfigData {
        let data = try encoder.encode(bindings)
        return ControlsConfigData(version: InputSourceControllerVersion.v1.rawValue, data: data)
    }

    func decode(_ data: consuming ControlsConfigData, decoder: JSONDecoder) throws -> InputSourceControllerBindings {
        guard let version = InputSourceControllerVersion(rawValue: data.version) else {
            throw ControlsInputError.unsupportedVersion
        }

        switch version {
        case .v1: return try decoder.decode(InputSourceControllerBindings.self, from: data.data)
        }
    }
}

extension GCController {
    var inputSourceDescriptor: InputSourceControllerDescriptor {
        InputSourceControllerDescriptor(id: vendorName)
    }
}
