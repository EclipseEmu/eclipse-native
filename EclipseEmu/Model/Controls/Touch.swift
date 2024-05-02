import Foundation
import EclipseKit

struct TouchLayout {
    var menuButton: ElementDisplay
    var controls: [Element]
    var variants: [Variant]
    
    struct Variant {
        var minWidth: UInt64?
        var minHeight: UInt64?
        var orientation: Orientation?
        
        var menuButton: ElementDisplay?
        var overrides: [Override]
        
        enum Orientation: UInt8 {
            case portrait = 0
            case landscape = 1
        }
    }
    
    struct Override {
        var index: Int
        var layout: ElementDisplay
    }
    
    struct ElementDisplay {
        var xOrigin: Origin
        var yOrigin: Origin
        var x: CGFloat
        var y: CGFloat
        var width: CGFloat
        var height: CGFloat
        var hidden: Bool
        
        enum Origin: UInt8 {
            case leading = 0
            case trailing = 1
        }
    }
    
    struct Element: Identifiable {
        var id = UUID()
        var label: String
        var style: Style = .automatic
        var layout: ElementDisplay
        var bindings: TouchLayout.Bindings
        
        enum Style: UInt8 {
            case automatic = 0
            case circle = 1
            case capsule = 2
        }
    }

    struct Bindings {
        var kind: Bindings.Kind
        var inputA: UInt32
        var inputB: GameInput
        var inputC: GameInput
        var inputD: GameInput
        
        enum Kind: UInt8 {
            case button
            case multiButton
            case joystick
            case dpad
        }
    }
}
