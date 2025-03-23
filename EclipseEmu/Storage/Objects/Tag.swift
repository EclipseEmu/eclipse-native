import SwiftUI

enum TagColor: Int16, RawRepresentable, Equatable {
    case red
    case orange
    case yellow
    case green
    case mint
    case teal
    case cyan
    case blue
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
    var parsedColor: TagColor {
        .init(rawValue: self.color) ?? .blue
    }

    convenience init(name: String, color: TagColor) {
        self.init(entity: Self.entity(), insertInto: nil)
        self.name = name
        self.color = color.rawValue
    }
}
