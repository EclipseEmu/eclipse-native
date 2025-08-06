import Foundation
import GameController
import EclipseKit

struct KeyboardMapping: Codable {
    var input: CoreInput
	var direction: ControlMappingDirection

	init(_ input: CoreInput, direction: ControlMappingDirection = .none) {
		self.input = input
		self.direction = direction
	}
}

typealias KeyboardMappings = [GCKeyCode : KeyboardMapping]

enum InputSourceKeyboardVersion: Int16, VersionProtocol {
    case v1 = 1
    
    static let latest: Self = .v1
}

struct InputSourceKeyboardDescriptor: InputSourceDescriptorProtocol {
    typealias Bindings = KeyboardMappings
	typealias Object = KeyboardProfileObject

	func obtain(from game: GameObject, system: System, persistence: Persistence) -> KeyboardProfileObject? {
		game.keyboardProfile
	}

	func predicate(system: System) -> NSPredicate {
		NSPredicate(format: "rawSystem = %d", system.rawValue)
	}

    static func encode(_ bindings: KeyboardMappings, encoder: JSONEncoder, into object: KeyboardProfileObject) throws {
        object.data = try encoder.encode(bindings)
    }

    static func decode(_ data: KeyboardProfileObject, decoder: JSONDecoder) throws -> KeyboardMappings {
        guard let version = data.version, let data = data.data else {
            return [:]
        }
        return switch version {
        case .v1: try decoder.decode(KeyboardMappings.self, from: data)
        }
    }

    static func defaults(for system: System) -> KeyboardMappings {
        switch system {
        case .gba:
            [
				.keyZ: .init(.faceButtonDown),
				.keyX: .init(.faceButtonRight),
				.keyA: .init(.leftShoulder),
				.keyS: .init(.rightShoulder),
				.upArrow: .init(.dpad, direction: .fullPositiveY),
				.downArrow: .init(.dpad, direction: .fullNegativeY),
				.leftArrow: .init(.dpad, direction: .fullNegativeX),
                .rightArrow: .init(.dpad, direction: .fullPositiveX),
				.returnOrEnter: .init(.start),
				.rightShift: .init(.select)
            ]
        default: [:]
        }
    }
}
