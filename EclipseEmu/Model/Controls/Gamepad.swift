import Foundation
import EclipseKit
import GameController

struct GamepadBinding {
    var control: String
    var kind: Kind
    
    enum Kind {
        case button(GameInput)
        case directionPad(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
        case joystick(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
        case gyro(x: GameInput, y: GameInput, z: GameInput)
        case touchPad(x: GameInput, y: GameInput)
    }
}

