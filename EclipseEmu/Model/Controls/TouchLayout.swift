import EclipseKit
import Foundation

extension GameInput: Codable {}

struct TouchLayout2: Codable {
    let controls: [Control]
    let breakpoints: [Breakpoints]

    enum Origin: UInt8, RawRepresentable, Codable {
        case start = 0
        case end = 1
    }

    enum Orientation: UInt8, Codable {
        case any = 0
        case portrait = 1
        case landscape = 2
    }

    struct Control: Codable {
        let id: UUID
        let input: ControlInput
    }

    enum ControlInput: Codable {
        case button(input: GameInput)
        case multiButton(inputs: GameInput.RawValue)
        case joystick(posY: GameInput, negY: GameInput, posX: GameInput, negX: GameInput)
        case dpad(up: GameInput, down: GameInput, left: GameInput, right: GameInput)
    }

    struct Breakpoints: Codable {
        let minWidth: CGFloat?
        let minHeight: CGFloat?
        let orientation: Orientation

        let menuButton: ElementLayout?
        let elements: [UUID: Element]
    }

    struct Element: Codable {
        let label: String
        let isHidden: Bool
        let shape: ElementShape
        let layout: ElementLayout
    }

    enum ElementShape: UInt8, RawRepresentable, Codable {
        case circle = 0
        case capsule = 1
    }

    struct ElementLayout: Codable {
        let xOrigin: Origin
        let yOrigin: Origin
        let xOffset: Float
        let yOffset: Float
        let width: Float
        let height: Float

        func rect(in size: CGSize, shape: ElementShape) -> CGRect {
            let width = CGFloat(width)
            let height = shape == .capsule ? CGFloat(height) : width

            return CGRect(
                x: xOrigin == .start ? CGFloat(xOffset) : size.width - CGFloat(xOffset) - CGFloat(width),
                y: yOrigin == .start ? CGFloat(yOffset) : size.height - CGFloat(yOffset) - CGFloat(height),
                width: width,
                height: height
            )
        }
    }
}

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
        // swiftlint:disable:next identifier_name
        var x: CGFloat
        // swiftlint:disable:next identifier_name
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
