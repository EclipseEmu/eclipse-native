import SwiftUI
import CoreData

let colors = [
    Color.blue,
    Color.indigo,
    Color.red,
    Color.green,
    Color.yellow,
    Color.orange,
    Color.purple,
    Color.pink
]

enum TagColor: Int16, RawRepresentable, Equatable, CaseIterable {
    case blue
    case red
    case orange
    case yellow
    case green
    case mint
    case teal
    case cyan
    case indigo
    case purple
    case pink
    case brown

    init(color: Color) {
        self = switch color {
        case .red: Self.red
        case .orange: Self.orange
        case .yellow: Self.yellow
        case .green: Self.green
        case .mint: Self.mint
        case .teal: Self.teal
        case .cyan: Self.cyan
        case .blue: Self.blue
        case .indigo: Self.indigo
        case .purple: Self.purple
        case .pink: Self.pink
        case .brown: Self.brown
        default: Self.blue
        }
    }

    var color: Color {
        return switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .cyan: .cyan
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        }
    }
}

extension Tag {
    var color: TagColor {
        get {
            .init(rawValue: rawColor) ?? .blue
        }
        set {
            rawColor = newValue.rawValue
        }
    }

    @discardableResult
    static func create(in context: NSManagedObjectContext, name: String, color: TagColor) -> Self {
        let model: Self = context.create()
        model.name = name
        model.color = color
        return model
    }
}
