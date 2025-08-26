import EclipseKit
import Foundation

struct GameInputCollection: Identifiable {
    let id = UUID()
    let items: [CoreInput]

    init(_ items: [CoreInput]) {
        self.items = items
    }
}

extension CoreInput {
    static let sectioned: [GameInputCollection] = [
        .init([.dpad]),
		.init([.leftJoystick, .leftJoystickPress]),
		.init([.rightJoystick, .rightJoystickPress]),
        .init([.faceButtonUp, .faceButtonDown, .faceButtonLeft, .faceButtonRight]),
        .init([.leftShoulder, .rightShoulder, .leftTrigger, .rightTrigger]),
        .init([.start, .select]),
		.init([.touchSurface, .touchPress]),
        .init([.sleep]),
    ]

    public static let allOn: CoreInput = [
		.faceButtonUp, .faceButtonDown, .faceButtonLeft, .faceButtonRight,
		.leftShoulder, .leftTrigger, .rightShoulder, .rightTrigger,
		.start, .select, .sleep,
		.dpad, .leftJoystick, .leftJoystickPress, .rightJoystick, .rightJoystickPress,
		.touchSurface, .touchPress
	]
}

extension CoreInput: @retroactive CaseIterable {
    public static let allCases: [CoreInput] = [
		.faceButtonUp, .faceButtonDown, .faceButtonLeft, .faceButtonRight,
		.leftShoulder, .leftTrigger, .rightShoulder, .rightTrigger,
		.start, .select, .sleep,
		.dpad, .leftJoystick, .leftJoystickPress, .rightJoystick, .rightJoystickPress,
		.touchSurface, .touchPress
    ]
}
