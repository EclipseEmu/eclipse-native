import EclipseKit
import Foundation
import GameController

typealias KeyboardBindings = [GCKeyCode: GameInput]

struct ControllerBindings {
    var id: UUID
    var system: GameSystem
    var gameId: UUID?
    var auxilaryId: UUID?
    var bindings: Data

    enum Bindings {
        case touch(TouchLayout)
        case gamepad([GamepadBinding])
        case keyboard(KeyboardBindings)
    }
}
