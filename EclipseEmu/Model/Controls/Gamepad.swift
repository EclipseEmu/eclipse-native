import EclipseKit
import Foundation
import GameController

struct GamepadBinding {
    var control: String
    var kind: Kind

    enum Kind {
        case button(GameInput)
        // swiftlint:disable:next identifier_name
        case directionPad(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
        // swiftlint:disable:next identifier_name
        case joystick(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
        // swiftlint:disable:next identifier_name
        case gyro(x: GameInput, y: GameInput, z: GameInput)
        // swiftlint:disable:next identifier_name
        case touchPad(x: GameInput, y: GameInput)
    }
}
