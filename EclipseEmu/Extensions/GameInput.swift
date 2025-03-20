import EclipseKit
import Foundation

extension GameInput {
    // NOTE: as more systems are added, this should take a naming convention argument
    var string: String {
        return switch self {
        case []: "None"
        case .faceButtonUp: "X"
        case .faceButtonDown: "B"
        case .faceButtonLeft: "Y"
        case .faceButtonRight: "A"
        case .startButton: "Start"
        case .selectButton: "Select"
        case .shoulderLeft: "L"
        case .shoulderRight: "R"
        case .triggerLeft: "ZL"
        case .triggerRight: "ZR"
        case .dpadUp: "Up"
        case .dpadDown: "Down"
        case .dpadLeft: "Left"
        case .dpadRight: "Right"
        case .leftJoystickUp: "Left Joystick Y+"
        case .leftJoystickDown: "Left Joystick Y-"
        case .leftJoystickLeft: "Left Joystick X-"
        case .leftJoystickRight: "Left Joystick X+"
        case .rightJoystickUp: "Right Joystick Y+"
        case .rightJoystickDown: "Right Joystick Y-"
        case .rightJoystickLeft: "Right Joystick X-"
        case .rightJoystickRight: "Right Joystick X+"
        case .touchPosX: "Touch X+"
        case .touchNegX: "Touch X-"
        case .touchPosY: "Touch Y+"
        case .touchNegY: "Touch Y-"
        case .lid: "Lid"
        case .mic: "Mic"
        case .gyroX: "Gryo X"
        case .gyroY: "Gryo Y"
        case .gyroZ: "Gryo Z"
        default: "Unknown"
        }
    }
}
