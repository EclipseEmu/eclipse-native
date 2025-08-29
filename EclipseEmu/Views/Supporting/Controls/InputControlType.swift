import EclipseKit

enum InputControlType: UInt8, RawRepresentable {
    case button = 0
    case dpad   = 1
    case analog = 2
    
    init(input: CoreInput) {
        self = switch input {
        case .dpad: .dpad
        case .leftJoystick, .rightJoystick, .touchSurface: .analog
        default: .button
        }
    }
}
