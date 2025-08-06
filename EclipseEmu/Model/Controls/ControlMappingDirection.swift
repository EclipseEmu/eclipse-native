import EclipseKit

enum ControlMappingDirection: UInt8, RawRepresentable, Codable, CaseIterable {
	case none = 0

	case fullPositiveY = 1
	case halfPositiveY = 2
	case fullNegativeY = 3
	case halfNegativeY = 4

	case fullNegativeX = 5
	case halfNegativeX = 6
	case fullPositiveX = 7
	case halfPositiveX = 8

	func intoValues(isPressed: Bool) -> (x: Float32, y: Float32) {
		let isPressedMultiplier: Float32 = isPressed ? 1.0 : 0.0
		return switch self {
		case .none: 		 (isPressedMultiplier, 0.0)
		case .fullPositiveY: (CoreInputDelta.IGNORE_VALUE, isPressedMultiplier * 1.0)
		case .halfPositiveY: (CoreInputDelta.IGNORE_VALUE, isPressedMultiplier * 0.5)
		case .fullNegativeY: (CoreInputDelta.IGNORE_VALUE, isPressedMultiplier * -1.0)
		case .halfNegativeY: (CoreInputDelta.IGNORE_VALUE, isPressedMultiplier * -0.5)
		case .fullPositiveX: (isPressedMultiplier * 1.0, CoreInputDelta.IGNORE_VALUE)
		case .halfPositiveX: (isPressedMultiplier * 0.5, CoreInputDelta.IGNORE_VALUE)
		case .fullNegativeX: (isPressedMultiplier * -1.0, CoreInputDelta.IGNORE_VALUE)
		case .halfNegativeX: (isPressedMultiplier * -0.5, CoreInputDelta.IGNORE_VALUE)
		}
	}
}

extension ControlMappingDirection {
    var label: String {
        switch self {
        case .none: "None"
        case .fullPositiveY: "Up"
        case .halfPositiveY: "Half Up"
        case .fullNegativeY: "Down"
        case .halfNegativeY: "Half Down"
        case .fullPositiveX: "Right"
        case .halfPositiveX: "Half Right"
        case .fullNegativeX: "Left"
        case .halfNegativeX: "Half Left"
        }
    }
}
