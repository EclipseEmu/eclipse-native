import Foundation
import GameController
import EclipseKit

struct ControllerBindings {
    var id: UUID
    var system: GameSystem
    var gameId: UUID?
    var auxilaryId: UUID?
    var bindings: Bindings
    
    enum Bindings {
        case touch(TouchLayout)
        case gamepad([GamepadBinding])
        case keyboard([GCKeyCode:GameInput])
    }
}
