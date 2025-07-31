import GameController
import EclipseKit

enum InputSourceControllerVersion: Int16, VersionProtocol {
    case v1 = 1
    
    static let latest: InputSourceControllerVersion = .v1
}

struct GamepadMappings: Codable {
    let bindings: [String : Self.Index]
    let buttons: [Self.ButtonBinding]
    let directionals: [Self.DirectionalBinding]

	enum Index: Codable {
        case button(Int)
        case directional(Int)
    }

	struct ButtonBinding: Codable {
        let soft: CoreInput
        let hard: CoreInput

        init(soft: CoreInput, hard: CoreInput) {
            self.soft = soft
            self.hard = hard
        }

        init(_ input: CoreInput) {
            self.soft = input
            self.hard = input
        }
    }

	struct DirectionalBinding: Codable {
        let input: CoreInput
        let deadzone: Float
    }
}

struct InputSourceControllerDescriptor: InputSourceDescriptorProtocol {
    typealias Bindings = GamepadMappings
	typealias Object = ControllerProfileObject

    let id: String?

	static func encode(_ bindings: GamepadMappings, encoder: JSONEncoder, into object: ControllerProfileObject) throws {
		object.data = try encoder.encode(bindings)
	}

	static func decode(_ data: ControllerProfileObject, decoder: JSONDecoder) throws -> GamepadMappings {
        guard let version = data.version, let data = data.data else {
            return .init(bindings: [:], buttons: [], directionals: [])
        }
		return switch version {
		case .v1: try decoder.decode(GamepadMappings.self, from: data)
		}
	}

	func obtain(from game: GameObject, system: System, persistence: Persistence) -> ControllerProfileObject? {
		guard let profiles = game.controllerProfiles as? Set<ControllerProfileObject> else { return nil }
        return profiles.first { profile in
            let isSystem = profile.system == system
            if isSystem && id != nil {
                return true
            }
            
            guard isSystem, let assignments = profile.assignments as? Set<ControllerProfileAssignmentObject> else {
                return false
            }
            
            for assignment in assignments {
                if system == assignment.system && assignment.controllerID == id {
                    return true
                }
            }

            return false
		}
	}

	func predicate(system: System) -> NSPredicate {
		if let id {
			NSPredicate(format: "rawSystem = %d AND controllerID = %@", system.rawValue, id)
		} else {
			NSPredicate(format: "rawSystem = %d", system.rawValue)
		}
	}

    static func defaults(for system: System) -> GamepadMappings {
        switch system {
        case .gb, .gbc, .nes:
			.init(
				bindings: [
					GCInputButtonA: .button(0),
					GCInputButtonB: .button(1),
					GCInputButtonMenu: .button(2),
					GCInputButtonOptions: .button(3),
					GCInputDirectionPad: .directional(0)
				],
				buttons: [
					.init(.faceButtonRight),
					.init(.faceButtonDown),
					.init(.start),
					.init(.select),
				],
				directionals: [
					.init(input: .dpad, deadzone: 0.5)
				]
			)
        case .gba:
			.init(
				bindings: [
					GCInputButtonA: .button(0),
					GCInputButtonB: .button(1),
					GCInputButtonMenu: .button(2),
					GCInputButtonOptions: .button(3),
					GCInputLeftShoulder: .button(4),
					GCInputLeftTrigger: .button(4),
					GCInputRightShoulder: .button(5),
					GCInputRightTrigger: .button(5),
					GCInputDirectionPad: .directional(0),
					GCInputLeftThumbstick: .directional(0)
				],
				buttons: [
					.init(.faceButtonRight),
					.init(.faceButtonDown),
					.init(.start),
					.init(.select),
					.init(.leftShoulder),
					.init(.rightShoulder)
				],
				directionals: [
					.init(input: .dpad, deadzone: 0.5)
				]
			)
        case .snes:
			.init(
				bindings: [
					GCInputButtonA: .button(0),
					GCInputButtonB: .button(1),
					GCInputButtonX: .button(2),
					GCInputButtonY: .button(3),
					GCInputButtonMenu: .button(4),
					GCInputButtonOptions: .button(5),
					GCInputLeftShoulder: .button(6),
					GCInputLeftTrigger: .button(6),
					GCInputRightShoulder: .button(7),
					GCInputRightTrigger: .button(7),
					GCInputDirectionPad: .directional(0),
					GCInputLeftThumbstick: .directional(0)
				],
				buttons: [
					.init(.faceButtonRight),
					.init(.faceButtonDown),
					.init(.faceButtonUp),
					.init(.faceButtonLeft),
					.init(.start),
					.init(.select),
					.init(.leftShoulder),
					.init(.rightShoulder)
				],
				directionals: [
					.init(input: .dpad, deadzone: 0.5)
				]
			)
        default:
			.init(bindings: [:], buttons: [], directionals: [])
        }
    }
}

extension GCController {
    var inputSourceDescriptor: InputSourceControllerDescriptor {
        InputSourceControllerDescriptor(id: vendorName)
    }
}
