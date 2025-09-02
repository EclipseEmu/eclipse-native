import GameController
import EclipseKit

enum InputSourceControllerVersion: Int16, InputSourceVersionProtocol {
    case v1 = 1
    
    static let latest: InputSourceControllerVersion = .v1
}

struct ControllerMappings: Codable {
    var bindings: [String : Self.Index]
    var buttons: [Self.ButtonBinding]
    var directionals: [Self.DirectionalBinding]

	enum Index: Codable {
        case button(Int)
        case directional(Int)
    }

	struct ButtonBinding: Hashable, Codable {
        let input: CoreInput
        let direction: ControlMappingDirection

        init(_ input: CoreInput, direction: ControlMappingDirection = .none) {
            self.input = input
            self.direction = direction
        }
    }

	struct DirectionalBinding: Hashable, Codable {
        let input: CoreInput
        let deadzone: Float
    }
}

struct InputSourceControllerDescriptor: InputSourceDescriptorProtocol {
    typealias Bindings = ControllerMappings
	typealias Object = ControllerProfileObject

    let id: String?
    
    static func encode(_ bindings: ControllerMappings, encoder: JSONEncoder, into object: ControllerProfileObject) throws {
        object.data = try encoder.encode(bindings)
    }

    static func decode(_ data: ControllerProfileObject, decoder: JSONDecoder) throws -> ControllerMappings {
        guard let version = data.version, let data = data.data else {
            return .init(bindings: [:], buttons: [], directionals: [])
        }
        return switch version {
        case .v1: try decoder.decode(ControllerMappings.self, from: data)
        }
    }

    func obtain(for game: GameObject) -> ControllerProfileObject? {
        if let id, let assignments = game.controllerProfileAssignments as? Set<ControllerProfileAssignmentObject> {
            if let assignment = assignments.first(where: { $0.controllerID == id }) {
                return assignment.profile
            }
        }
        
        return game.controllerProfile
    }
    
    @MainActor
    func obtain(for system: System, persistence: Persistence, settings: Settings) -> ControllerProfileObject? {
        if let id {
            let request = ControllerProfileAssignmentObject.fetchRequest()
            request.fetchLimit = 1
            request.includesSubentities = false
            request.sortDescriptors = [.init(keyPath: \ControllerProfileAssignmentObject.controllerID, ascending: true)]
            request.predicate = NSPredicate(format: "rawSystem = %d AND controllerID = %@", system.rawValue, id)
            if let assignment = try? persistence.mainContext.fetch(request).first, let profile = assignment.profile {
                return profile
            }
        }

        return settings.controllerSystemProfiles[system]?.tryGet(in: persistence.mainContext)
    }
    
    static func defaults(for system: System) -> ControllerMappings {
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
    
    var persistentID: String {
        vendorName ?? self.productCategory
    }
}
