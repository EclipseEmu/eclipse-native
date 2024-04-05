import Foundation
import EclipseKit

struct GamepadBinding {
    var kind: Kind
    var index: UInt32
    var direction: Direction
    var deadZone: Float32
    var input: GameInput
    
    enum Kind: UInt8 {
        case button
        case axis
    }
    
    enum Direction: UInt8 {
        case negative = 0
        case positive = 1
    }
}
