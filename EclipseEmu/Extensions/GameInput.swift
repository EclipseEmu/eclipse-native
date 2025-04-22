import EclipseKit
import Foundation

struct GameInputCollection: Identifiable {
    let id = UUID()
    let items: [GameInput]

    init(_ items: [GameInput]) {
        self.items = items
    }
}

extension GameInput {
    // NOTE: as more systems are added, this should take a naming convention argument
    var string: String {
        return switch self {
        case .faceButtonUp: "X Button"
        case .faceButtonDown: "B Button"
        case .faceButtonLeft: "Y Button"
        case .faceButtonRight: "A Button"

        case .startButton: "Start Button"
        case .selectButton: "Select Button"

        case .shoulderLeft: "Left Shoulder Button"
        case .shoulderRight: "Right Shoulder Button"
            
        case .triggerLeft: "Left Trigger Button"
        case .triggerRight: "Right Trigger Button"
            
        case .dpadUp: "Direction Pad Up"
        case .dpadDown: "Direction Pad Down"
        case .dpadLeft: "Direction Pad Left"
        case .dpadRight: "Direction Pad Right"
            
        case .leftJoystickUp: "Left Thumbstick Up"
        case .leftJoystickDown: "Left Thumbstick Down"
        case .leftJoystickLeft: "Left Thumbstick Left"
        case .leftJoystickRight: "Left Thumbstick Right"

        case .rightJoystickUp: "Right Thumbstick Up"
        case .rightJoystickDown: "Right Thumbstick Down"
        case .rightJoystickLeft: "Right Thumbstick Left"
        case .rightJoystickRight: "Right Thumbstick Right"
        case .touchPosX: "Touch X+"
        case .touchNegX: "Touch X-"
        case .touchPosY: "Touch Y+"
        case .touchNegY: "Touch Y-"
        case .lid: "Toggle Lid"
        case .mic: "Mic"
        case .gyroX: "Gryo X"
        case .gyroY: "Gryo Y"
        case .gyroZ: "Gryo Z"
        default: "Unknown"
        }
    }

    var systemImage: String {
        return switch self {
        case .faceButtonUp:         "circle.grid.cross.up.filled"
        case .faceButtonDown:       "circle.grid.cross.down.filled"
        case .faceButtonLeft:       "circle.grid.cross.left.filled"
        case .faceButtonRight:      "circle.grid.cross.right.filled"

        case .dpadUp:               "dpad.up.filled"
        case .dpadDown:             "dpad.down.filled"
        case .dpadLeft:             "dpad.left.filled"
        case .dpadRight:            "dpad.right.filled"

        case .startButton:          "plus.circle"
        case .selectButton:         "minus.circle"
        case .shoulderLeft:         "lb.button.roundedbottom.horizontal"
        case .shoulderRight:        "rb.button.roundedbottom.horizontal"
        case .triggerLeft:          "lt.button.roundedtop.horizontal"
        case .triggerRight:         "rt.button.roundedtop.horizontal"

        case .leftJoystickUp:       "l.joystick.tilt.up"
        case .leftJoystickDown:     "l.joystick.tilt.down"
        case .leftJoystickLeft:     "l.joystick.tilt.left"
        case .leftJoystickRight:    "l.joystick.tilt.right"

        case .rightJoystickUp:      "r.joystick.tilt.up"
        case .rightJoystickDown:    "r.joystick.tilt.down"
        case .rightJoystickLeft:    "r.joystick.tilt.left"
        case .rightJoystickRight:   "r.joystick.tilt.right"

        case .touchPosX:            "arrow.right.square"
        case .touchNegX:            "arrow.left.square"
        case .touchPosY:            "arrow.down.square"
        case .touchNegY:            "arrow.up.square"

        case .lid:                  "sleep"
        case .mic:                  "microphone"

        case .gyroX:                "arrow.right.circle"
        case .gyroY:                "arrow.down.circle"
        case .gyroZ:                "arrow.uturn.up.circle"

        default: "circle"
        }
    }

    static let sectioned: [GameInputCollection] = [
        .init([.dpadUp, .dpadDown, .dpadLeft, .dpadRight]),
        .init([.faceButtonUp, .faceButtonDown, .faceButtonLeft, .faceButtonRight]),
        .init([.shoulderLeft, .shoulderRight, .triggerLeft, .triggerRight]),
        .init([.startButton, .selectButton]),
        .init([.leftJoystickUp, .leftJoystickDown, .leftJoystickLeft, .leftJoystickRight]),
        .init([.rightJoystickUp, .rightJoystickDown, .rightJoystickLeft, .rightJoystickRight]),
        .init([.touchPosX, .touchNegX, .touchPosY, .touchNegY]),
        .init([.gyroX, .gyroY, .gyroZ]),
        .init([.lid, .mic]),
    ]

    public static let allOn: GameInput = [
        .faceButtonUp, .faceButtonDown, .faceButtonLeft, .faceButtonRight,
        .dpadUp, .dpadDown, .dpadLeft, .dpadRight,
        .shoulderLeft, .shoulderRight, .triggerLeft, .triggerRight,
        .leftJoystickUp, .leftJoystickDown, .leftJoystickLeft, .leftJoystickRight,
        .rightJoystickUp, .rightJoystickDown, .rightJoystickLeft, .rightJoystickRight,
        .touchPosX, .touchNegX, .touchPosY, .touchNegY,
        .startButton, .selectButton, .lid, .mic,
        .gyroX, .gyroY, .gyroZ
    ]
}

extension GameInput: @retroactive CaseIterable {
    public static let allCases: [GameInput] = [
        .dpadUp, .dpadDown, .dpadLeft, .dpadRight,
        .faceButtonRight, .faceButtonDown, .faceButtonUp, .faceButtonLeft,
        .startButton, .selectButton,
        .shoulderLeft, .shoulderRight, .triggerLeft, .triggerRight,
        .leftJoystickUp, .leftJoystickDown, .leftJoystickLeft, .leftJoystickRight,
        .rightJoystickUp, .rightJoystickDown, .rightJoystickLeft, .rightJoystickRight,
        .touchPosX, .touchNegX, .touchPosY, .touchNegY,
        .lid, .mic,
        .gyroX, .gyroY, .gyroZ
    ]
}
