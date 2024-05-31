import Foundation
import SwiftUI

extension GameCollection {
    enum Color: Int16, RawRepresentable, Equatable {
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

        // swiftlint:disable:next cyclomatic_complexity
        init(color: SwiftUI.Color) {
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

        var color: SwiftUI.Color {
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

    enum Icon: Equatable {
        case unknown
        case symbol(String)
        //        case emoji(String)

        var kind: Int16 {
            switch self {
            case .unknown:
                return 0
            case .symbol:
                return 1
            }
        }

        var content: String? {
            switch self {
            case .symbol(let string):
                return string
            default:
                return nil
            }
        }

        static func from(kind: Int16, content: String?) -> Self {
            guard let content else { return .unknown }
            switch kind {
            case 1:
                return .symbol(content)
            default:
                return .unknown
            }
        }
    }

    var parsedColor: GameCollection.Color {
        GameCollection.Color(rawValue: self.color) ?? .blue
    }

    var icon: GameCollection.Icon {
        get {
            Self.Icon.from(kind: self.iconKind, content: self.iconContent)
        }
        set {
            self.iconKind = newValue.kind
            self.iconContent = newValue.content
        }
    }
}
