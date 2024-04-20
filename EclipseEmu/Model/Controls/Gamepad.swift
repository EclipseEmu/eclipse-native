import Foundation
import EclipseKit

// FIXME: this doesn't really reflect the way GCExtendedGamepad works
struct GamepadBinding {
    var kind: Kind
    var id: String
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
