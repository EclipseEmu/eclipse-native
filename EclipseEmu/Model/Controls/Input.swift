import Foundation

@objc(ECGameInput)
enum GameInput: UInt32, RawRepresentable {
    case none                 = 0b00000000_00000000_00000000_00000000
    case faceButtonUp         = 0b00000000_00000000_00000000_00000001
    case faceButtonDown       = 0b00000000_00000000_00000000_00000010
    case faceButtonLeft       = 0b00000000_00000000_00000000_00000100
    case faceButtonRight      = 0b00000000_00000000_00000000_00001000
    case startButton          = 0b00000000_00000000_00000000_00010000
    case selectButton         = 0b00000000_00000000_00000000_00100000
    case shoulderLeft         = 0b00000000_00000000_00000000_01000000
    case shoulderRight        = 0b00000000_00000000_00000000_10000000
    case triggerLeft          = 0b00000000_00000000_00000001_00000000
    case triggerRight         = 0b00000000_00000000_00000010_00000000
    case dpadUp               = 0b00000000_00000000_00000100_00000000
    case dpadDown             = 0b00000000_00000000_00001000_00000000
    case dpadLeft             = 0b00000000_00000000_00010000_00000000
    case dpadRight            = 0b00000000_00000000_00100000_00000000
    case leftJoystickUp       = 0b00000000_00000000_01000000_00000000
    case leftJoystickDown     = 0b00000000_00000000_10000000_00000000
    case leftJoystickLeft     = 0b00000000_00000001_00000000_00000000
    case leftJoystickRight    = 0b00000000_00000010_00000000_00000000
    case rightJoystickUp      = 0b00000000_00000100_00000000_00000000
    case rightJoystickDown    = 0b00000000_00001000_00000000_00000000
    case rightJoystickLeft    = 0b00000000_00010000_00000000_00000000
    case rightJoystickRight   = 0b00000000_00100000_00000000_00000000
    case touchPosX            = 0b00000000_01000000_00000000_00000000
    case touchNegX            = 0b00000000_10000000_00000000_00000000
    case touchPosY            = 0b00000001_00000000_00000000_00000000
    case touchNegY            = 0b00000010_00000000_00000000_00000000
    case lid                  = 0b00000100_00000000_00000000_00000000
    case mic                  = 0b00001000_00000000_00000000_00000000
    
    // NOTE: as more systems are added, this should take a naming convention argument
    func toString() -> String {
    return switch self {
    case .none:
        "None"
    case .faceButtonUp:
        "X"
    case .faceButtonDown:
        "B"
    case .faceButtonLeft:
        "Y"
    case .faceButtonRight:
        "A"
    case .startButton:
        "Start"
    case .selectButton:
        "Select"
    case .shoulderLeft:
        "L"
    case .shoulderRight:
        "R"
    case .triggerLeft:
        "ZL"
    case .triggerRight:
        "ZR"
    case .dpadUp:
        "Up"
    case .dpadDown:
        "Down"
    case .dpadLeft:
        "Left"
    case .dpadRight:
        "Right"
    case .leftJoystickUp:
        "Left Joystick Y+"
    case .leftJoystickDown:
        "Left Joystick Y-"
    case .leftJoystickLeft:
        "Left Joystick X-"
    case .leftJoystickRight:
        "Left Joystick X+"
    case .rightJoystickUp:
        "Right Joystick Y+"
    case .rightJoystickDown:
        "Right Joystick Y-"
    case .rightJoystickLeft:
        "Right Joystick X-"
    case .rightJoystickRight:
        "Right Joystick X+"
    case .touchPosX:
        "Touch X+"
    case .touchNegX:
        "Touch X-"
    case .touchPosY:
        "Touch Y+"
    case .touchNegY:
        "Touch Y-"
    case .lid:
        "Lid"
    case .mic:
        "Mic"
    }
    }
}
