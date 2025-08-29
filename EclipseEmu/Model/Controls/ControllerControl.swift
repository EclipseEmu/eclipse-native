import SwiftUI
import GameController

enum ControllerButtonNaming: UInt8, RawRepresentable {
    case nintendo
    case xbox
    case playstation
}

enum ControllerControlKind: UInt8, RawRepresentable {
    case button
    case directional
}

struct ControllerControl: Hashable, Identifiable {
    let id: String
    
    init(rawValue: String) {
        self.id = rawValue
    }

    static let buttonA                  = Self(rawValue: GCInputButtonA)
    static let buttonB                  = Self(rawValue: GCInputButtonB)
    static let buttonX                  = Self(rawValue: GCInputButtonX)
    static let buttonY                  = Self(rawValue: GCInputButtonY)
    static let directionPad             = Self(rawValue: GCInputDirectionPad)
    static let leftThumbstick           = Self(rawValue: GCInputLeftThumbstick)
    static let rightThumbstick          = Self(rawValue: GCInputRightThumbstick)
    static let leftShoulder             = Self(rawValue: GCInputLeftShoulder)
    static let rightShoulder            = Self(rawValue: GCInputRightShoulder)
    static let leftTrigger              = Self(rawValue: GCInputLeftTrigger)
    static let rightTrigger             = Self(rawValue: GCInputRightTrigger)
    static let leftThumbstickButton     = Self(rawValue: GCInputLeftThumbstickButton)
    static let rightThumbstickButton    = Self(rawValue: GCInputRightThumbstickButton)
    static let buttonHome               = Self(rawValue: GCInputButtonHome)
    static let buttonMenu               = Self(rawValue: GCInputButtonMenu)
    static let buttonOptions            = Self(rawValue: GCInputButtonOptions)
    static let buttonShare              = Self(rawValue: GCInputButtonShare)
    static let xboxPaddleOne            = Self(rawValue: GCInputXboxPaddleOne)
    static let xboxPaddleTwo            = Self(rawValue: GCInputXboxPaddleTwo)
    static let xboxPaddleThree          = Self(rawValue: GCInputXboxPaddleThree)
    static let xboxPaddleFour           = Self(rawValue: GCInputXboxPaddleFour)
    static let dualShockTouchpadOne     = Self(rawValue: GCInputDualShockTouchpadOne)
    static let dualShockTouchpadTwo     = Self(rawValue: GCInputDualShockTouchpadTwo)
    static let dualShockTouchpadButton  = Self(rawValue: GCInputDualShockTouchpadButton)
    
    static let allControls: [(ControllerControl, ControllerControlKind)] = [
        (.buttonA, .button),
        (.buttonB, .button),
        (.buttonX, .button),
        (.buttonY, .button),
        (.directionPad, .directional),
        (.leftThumbstick, .directional),
        (.rightThumbstick, .directional),
        (.leftShoulder, .button),
        (.rightShoulder, .button),
        (.leftTrigger, .button),
        (.rightTrigger, .button),
        (.leftThumbstickButton, .button),
        (.rightThumbstickButton, .button),
        (.buttonHome, .button),
        (.buttonMenu, .button),
        (.buttonOptions, .button),
        (.buttonShare, .button),
        (.xboxPaddleOne, .button),
        (.xboxPaddleTwo, .button),
        (.xboxPaddleThree, .button),
        (.xboxPaddleFour, .button),
        (.dualShockTouchpadOne, .directional),
        (.dualShockTouchpadTwo, .directional),
        (.dualShockTouchpadButton, .button),
    ]
    
    func label(for naming: ControllerButtonNaming) -> (LocalizedStringKey, systemImage: String) {
        switch naming {
        case .nintendo:
            switch self {
            // FIXME: are these mapped properly or do they need to be swapped?
            case .buttonA:                  ("CONTROLLER_BUTTON_A", systemImage: "a.circle")
            case .buttonB:                  ("CONTROLLER_BUTTON_B", systemImage: "b.circle")
            case .buttonX:                  ("CONTROLLER_BUTTON_X", systemImage: "x.circle")
            case .buttonY:                  ("CONTROLLER_BUTTON_Y", systemImage: "y.circle")
            case .directionPad:             ("CONTROLLER_DPAD", systemImage: "dpad")
            case .leftThumbstick:           ("CONTROLLER_LEFT_THUMBSTICK", systemImage: "l.joystick")
            case .leftThumbstickButton:     ("CONTROLLER_LEFT_THUMBSTICK_BUTTON", systemImage: "l.joystick.press.down")
            case .rightThumbstick:          ("CONTROLLER_RIGHT_THUMBSTICK", systemImage: "r.joystick")
            case .rightThumbstickButton:    ("CONTROLLER_RIGHT_THUMBSTICK_BUTTON", systemImage: "r.joystick.press.down")
            case .leftShoulder:             ("CONTROLLER_LEFT_SHOULDER", systemImage: "l.button.roundedbottom.horizontal")
            case .leftTrigger:              ("CONTROLLER_LEFT_TRIGGER", systemImage: "zl.button.roundedtop.horizontal")
            case .rightShoulder:            ("CONTROLLER_RIGHT_SHOULDER", systemImage: "r.button.roundedbottom.horizontal")
            case .rightTrigger:             ("CONTROLLER_RIGHT_TRIGGER", systemImage: "zr.button.roundedtop.horizontal")
            case .buttonHome:               ("CONTROLLER_HOME", systemImage: "house.circle")
            case .buttonMenu:               ("CONTROLLER_START", systemImage: "plus.circle")
            case .buttonOptions:            ("CONTROLLER_SELECT", systemImage: "minus.circle")
            case .buttonShare:              ("CONTROLLER_SCREENSHOT", systemImage: "circle.square")
            case .xboxPaddleOne:            ("CONTROLLER_XBOX_PADDLE_ONE", systemImage: "p1.button.horizontal")
            case .xboxPaddleTwo:            ("CONTROLLER_XBOX_PADDLE_TWO", systemImage: "p2.button.horizontal")
            case .xboxPaddleThree:          ("CONTROLLER_XBOX_PADDLE_THREE", systemImage: "p3.button.horizontal")
            case .xboxPaddleFour:           ("CONTROLLER_XBOX_PADDLE_FOUR", systemImage: "p4.button.horizontal")
            case .dualShockTouchpadOne:     ("CONTROLLER_DUALSHOCK_TOUCHPAD_ONE", systemImage: "inset.filled.lefthalf.rectangle")
            case .dualShockTouchpadTwo:     ("CONTROLLER_DUALSHOCK_TOUCHPAD_TWO", systemImage: "inset.filled.righthalf.rectangle")
            case .dualShockTouchpadButton:  ("CONTROLLER_DUALSHOCK_TOUCHPAD_BUTTON", systemImage: "hand.tap")
            default:                        ("UNKNOWN", systemImage: "circle.dashed")
            }
        case .xbox:
            switch self {
            case .buttonA:                  ("CONTROLLER_BUTTON_A", systemImage: "a.circle")
            case .buttonB:                  ("CONTROLLER_BUTTON_B", systemImage: "b.circle")
            case .buttonX:                  ("CONTROLLER_BUTTON_X", systemImage: "x.circle")
            case .buttonY:                  ("CONTROLLER_BUTTON_Y", systemImage: "y.circle")
            case .directionPad:             ("CONTROLLER_DPAD", systemImage: "dpad")
            case .leftThumbstick:           ("CONTROLLER_LEFT_THUMBSTICK", systemImage: "l.joystick")
            case .leftThumbstickButton:     ("CONTROLLER_LEFT_THUMBSTICK_BUTTON", systemImage: "l.joystick.press.down")
            case .rightThumbstick:          ("CONTROLLER_RIGHT_THUMBSTICK", systemImage: "r.joystick")
            case .rightThumbstickButton:    ("CONTROLLER_RIGHT_THUMBSTICK_BUTTON", systemImage: "r.joystick.press.down")
            case .leftShoulder:             ("CONTROLLER_LEFT_SHOULDER", systemImage: "lb.button.roundedbottom.horizontal")
            case .leftTrigger:              ("CONTROLLER_LEFT_TRIGGER", systemImage: "lt.button.roundedtop.horizontal")
            case .rightShoulder:            ("CONTROLLER_RIGHT_SHOULDER", systemImage: "rb.button.roundedbottom.horizontal")
            case .rightTrigger:             ("CONTROLLER_RIGHT_TRIGGER", systemImage: "rt.button.roundedtop.horizontal")
            case .buttonHome:               ("CONTROLLER_HOME", systemImage: "xbox.logo")
            case .buttonMenu:               ("CONTROLLER_MENU", systemImage: "line.3.horizontal.circle")
            case .buttonOptions:            ("CONTROLLER_OPTIONS", systemImage: "rectangle.on.rectangle.circle")
            case .buttonShare:              ("CONTROLLER_SHARE", systemImage: "square.and.arrow.up.circle")
            case .xboxPaddleOne:            ("CONTROLLER_XBOX_PADDLE_ONE", systemImage: "p1.button.horizontal")
            case .xboxPaddleTwo:            ("CONTROLLER_XBOX_PADDLE_TWO", systemImage: "p2.button.horizontal")
            case .xboxPaddleThree:          ("CONTROLLER_XBOX_PADDLE_THREE", systemImage: "p3.button.horizontal")
            case .xboxPaddleFour:           ("CONTROLLER_XBOX_PADDLE_FOUR", systemImage: "p4.button.horizontal")
            case .dualShockTouchpadOne:     ("CONTROLLER_DUALSHOCK_TOUCHPAD_ONE", systemImage: "inset.filled.lefthalf.rectangle")
            case .dualShockTouchpadTwo:     ("CONTROLLER_DUALSHOCK_TOUCHPAD_TWO", systemImage: "inset.filled.righthalf.rectangle")
            case .dualShockTouchpadButton:  ("CONTROLLER_DUALSHOCK_TOUCHPAD_BUTTON", systemImage: "hand.tap")
            default:                        ("UNKNOWN", systemImage: "circle.dashed")
            }
        case .playstation:
            switch self {
            case .buttonA:                  ("CONTROLLER_BUTTON_CROSS", systemImage: "xmark.circle")
            case .buttonB:                  ("CONTROLLER_BUTTON_CIRCLE", systemImage: "circle.circle")
            case .buttonX:                  ("CONTROLLER_BUTTON_SQUARE", systemImage: "square.circle")
            case .buttonY:                  ("CONTROLLER_BUTTON_TRIANGLE", systemImage: "triangle.circle")
            case .directionPad:             ("CONTROLLER_DPAD", systemImage: "dpad")
            case .leftThumbstick:           ("CONTROLLER_LEFT_THUMBSTICK", systemImage: "l.joystick")
            case .leftThumbstickButton:     ("CONTROLLER_LEFT_THUMBSTICK_BUTTON", systemImage: "l.joystick.press.down")
            case .rightThumbstick:          ("CONTROLLER_RIGHT_THUMBSTICK", systemImage: "r.joystick")
            case .rightThumbstickButton:    ("CONTROLLER_RIGHT_THUMBSTICK_BUTTON", systemImage: "r.joystick.press.down")
            case .leftShoulder:             ("CONTROLLER_LEFT_SHOULDER", systemImage: "l1.button.roundedbottom.horizontal")
            case .leftTrigger:              ("CONTROLLER_LEFT_TRIGGER", systemImage: "l2.button.roundedtop.horizontal")
            case .rightShoulder:            ("CONTROLLER_RIGHT_SHOULDER", systemImage: "r1.button.roundedbottom.horizontal")
            case .rightTrigger:             ("CONTROLLER_RIGHT_TRIGGER", systemImage: "r2.button.roundedtop.horizontal")
            case .buttonHome:               ("CONTROLLER_HOME", systemImage: "playstation.logo")
            case .buttonMenu:               ("CONTROLLER_OPTIONS", systemImage: "line.3.horizontal.circle")
            case .buttonOptions:            ("CONTROLLER_SHARE", systemImage: "square.and.arrow.up.circle")
            case .buttonShare:              ("CONTROLLER_NA", systemImage: "circle.dashed")
            case .xboxPaddleOne:            ("CONTROLLER_XBOX_PADDLE_ONE", systemImage: "p1.button.horizontal")
            case .xboxPaddleTwo:            ("CONTROLLER_XBOX_PADDLE_TWO", systemImage: "p2.button.horizontal")
            case .xboxPaddleThree:          ("CONTROLLER_XBOX_PADDLE_THREE", systemImage: "p3.button.horizontal")
            case .xboxPaddleFour:           ("CONTROLLER_XBOX_PADDLE_FOUR", systemImage: "p4.button.horizontal")
            case .dualShockTouchpadOne:     ("CONTROLLER_DUALSHOCK_TOUCHPAD_ONE", systemImage: "inset.filled.lefthalf.rectangle")
            case .dualShockTouchpadTwo:     ("CONTROLLER_DUALSHOCK_TOUCHPAD_TWO", systemImage: "inset.filled.righthalf.rectangle")
            case .dualShockTouchpadButton:  ("CONTROLLER_DUALSHOCK_TOUCHPAD_BUTTON", systemImage: "hand.tap")
            default:                        ("UNKNOWN", systemImage: "circle.dashed")
            }
        }
    }
}
