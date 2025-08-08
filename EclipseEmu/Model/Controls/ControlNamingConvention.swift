import EclipseKit

enum ControlNamingConvention {
	case nintendo
	case playstation
	case xbox
}

extension CoreInput {
    // FIXME: Localize
    func label(for convention: ControlNamingConvention) -> (String, systemImage: String) {
		switch convention {
		case .nintendo:
			switch self {
			case []: ("None", systemImage: "circle.dashed")
			case .dpad: ("D-Pad", systemImage: "dpad")
			case .faceButtonRight: ("A", systemImage: "a.circle")
			case .faceButtonDown: ("B", systemImage: "b.circle")
			case .faceButtonUp: ("X", systemImage: "x.circle")
			case .faceButtonLeft: ("Y", systemImage: "y.circle")
			case .leftJoystick: ("Left Thumbstick", systemImage: "l.joystick")
			case .leftJoystickPress: ("Left Thumbstick Press", systemImage: "l.joystick.press.down")
			case .rightJoystick: ("Right Thumbstick", systemImage: "r.joystick")
			case .rightJoystickPress: ("Right Thumbstick Press", systemImage: "r.joystick.press.down")
			case .leftShoulder: ("L", systemImage: "l.button.roundedbottom.horizontal")
			case .leftTrigger: ("ZL", systemImage: "zl.button.roundedtop.horizontal")
			case .rightShoulder: ("R", systemImage: "r.button.roundedbottom.horizontal")
			case .rightTrigger: ("ZR", systemImage: "zr.button.roundedtop.horizontal")
			case .start: ("Start", systemImage: "plus.circle")
			case .select: ("Select", systemImage: "minus.circle")
			case .touchSurface: ("Touch Move", systemImage: "hand.draw")
			case .touchPress: ("Touch Down", systemImage: "hand.tap")
			case .sleep: ("Sleep", systemImage: "sleep.circle")
			default: ("\(rawValue.nonzeroBitCount) Inputs", systemImage: "circlebadge.2")
			}
		case .playstation:
			switch self {
			case []: ("None", systemImage: "circle.dashed")
			case .dpad: ("D-Pad", systemImage: "dpad")
			case .faceButtonRight: ("Circle", systemImage: "circle.circle")
			case .faceButtonDown: ("Cross", systemImage: "xmark.circle")
			case .faceButtonUp: ("Triangle", systemImage: "triangle.circle")
			case .faceButtonLeft: ("Square", systemImage: "square.circle")
			case .leftJoystick: ("Left Thumbstick", systemImage: "l.joystick")
			case .leftJoystickPress: ("L3", systemImage: "l.joystick.press.down")
			case .rightJoystick: ("Right Thumbstick", systemImage: "r.joystick")
			case .rightJoystickPress: ("R3", systemImage: "r.joystick.press.down")
			case .leftShoulder: ("L1", systemImage: "l1.button.roundedbottom.horizontal")
			case .leftTrigger: ("L2", systemImage: "l2.button.roundedtop.horizontal")
			case .rightShoulder: ("R1", systemImage: "r1.button.roundedbottom.horizontal")
			case .rightTrigger: ("R2", systemImage: "r2.button.roundedtop.horizontal")
			case .start: ("Start", systemImage: "plus.circle")
			case .select: ("Select", systemImage: "minus.circle")
			case .touchSurface: ("Touch Move", systemImage: "hand.draw")
			case .touchPress: ("Touch Down", systemImage: "hand.tap")
			case .sleep: ("Sleep", systemImage: "sleep.circle")
			default: ("\(rawValue.nonzeroBitCount) Inputs", systemImage: "circlebadge.2")
			}
		case .xbox:
			switch self {
			case []: ("None", systemImage: "circle.dashed")
			case .dpad: ("D-Pad", systemImage: "dpad")
			case .faceButtonRight: ("B", systemImage: "b.circle")
			case .faceButtonDown: ("A", systemImage: "a.circle")
			case .faceButtonUp: ("Y", systemImage: "y.circle")
			case .faceButtonLeft: ("X", systemImage: "x.circle")
			case .leftJoystick: ("Left Thumbstick", systemImage: "l.joystick")
			case .leftJoystickPress: ("Left Thumbstick Press", systemImage: "l.joystick.press.down")
			case .rightJoystick: ("Right Thumbstick", systemImage: "r.joystick")
			case .rightJoystickPress: ("Right Thumbstick Press", systemImage: "r.joystick.press.down")
			case .leftShoulder: ("LB", systemImage: "lb.button.roundedbottom.horizontal")
			case .leftTrigger: ("LT", systemImage: "lt.button.roundedtop.horizontal")
			case .rightShoulder: ("RB", systemImage: "rb.button.roundedbottom.horizontal")
			case .rightTrigger: ("RT", systemImage: "rt.button.roundedtop.horizontal")
			case .start: ("View", systemImage: "line.3.horizontal.circle")
			case .select: ("Menu", systemImage: "rectangle.on.rectangle.circle")
			case .touchSurface: ("Touch Move", systemImage: "hand.draw")
			case .touchPress: ("Touch Down", systemImage: "hand.tap")
			case .sleep: ("Sleep", systemImage: "sleep.circle")
			default: ("\(rawValue.nonzeroBitCount) Inputs", systemImage: "circlebadge.2")
			}
		}
	}
}
