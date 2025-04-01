import Foundation
import GameController
import EclipseKit

typealias GameKeyboardBindings = [GCKeyCode : GameInput]

private enum InputSourceKeyboardVersion: Int16, RawRepresentable {
    case v1 = 1
}

struct InputSourceKeyboardDescriptor: InputSourceDescriptorProtocol {
    typealias Bindings = GameKeyboardBindings

    let kind: ControlsInputSourceKind = .keyboard
    let id: String? = nil

    func encode(_ bindings: GameKeyboardBindings, encoder: JSONEncoder) throws -> ControlsConfigData {
        let data = try encoder.encode(bindings)
        return ControlsConfigData(version: InputSourceKeyboardVersion.v1.rawValue, data: data)
    }

    func decode(_ data: consuming ControlsConfigData, decoder: JSONDecoder) throws -> GameKeyboardBindings {
        guard let version = InputSourceKeyboardVersion(rawValue: data.version) else {
            throw ControlsInputError.unsupportedVersion
        }

        switch version {
        case .v1:
            return try decoder.decode(GameKeyboardBindings.self, from: data.data)
        }
    }

    static func defaults(for system: GameSystem) -> GameKeyboardBindings {
        switch system {
        case .gba:
            [
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
        default: [:]
        }
    }
}

extension GCKeyboard {
    static let inputSourceDescriptor = InputSourceKeyboardDescriptor()
}
