import CoreData
import Foundation
import SwiftUI

@objc(GameCollection)
public final class GameCollection: NSManagedObject, Identifiable {
    @nonobjc public static func fetchRequest() -> NSFetchRequest<GameCollection> {
        return NSFetchRequest<GameCollection>(entityName: "GameCollection")
    }

    private enum IntermediateColor: Int16, RawRepresentable, Equatable {
        case red = 0
        case orange = 1
        case yellow = 2
        case green = 3
        case mint = 4
        case teal = 5
        case cyan = 6
        case blue = 7
        case indigo = 8
        case purple = 9
        case pink = 10
        case brown = 11
    }

    enum Icon: Equatable {
        case unknown
        case symbol(String)

        static let symbolKind: Int16 = 1

        var kind: Int16 {
            switch self {
            case .unknown: 0
            case .symbol: Self.symbolKind
            }
        }

        var content: String? {
            switch self {
            case .symbol(let string): string
            default: nil
            }
        }
    }

    @NSManaged public var rawColor: Int16
    @NSManaged public var rawIconContent: String?
    @NSManaged public var rawIconKind: Int16
    @NSManaged public var name: String?
    @NSManaged public var games: NSSet?

    // MARK: Accessors for games

    @objc(addGamesObject:)
    @NSManaged public func addToGames(_ value: Game)

    @objc(removeGamesObject:)
    @NSManaged public func removeFromGames(_ value: Game)

    @objc(addGames:)
    @NSManaged public func addToGames(_ values: NSSet)

    // MARK: Getters

    var icon: Icon {
        get {
            guard let rawIconContent else { return .unknown }
            return switch rawIconKind {
            case Icon.symbolKind: .symbol(rawIconContent)
            default: .unknown
            }
        }
        set {
            self.rawIconKind = newValue.kind
            self.rawIconContent = newValue.content
        }
    }

    var color: Color {
        get {
            return switch IntermediateColor(rawValue: self.rawColor) ?? .blue {
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
        set {
            self.rawColor = switch newValue {
            case .red: IntermediateColor.red.rawValue
            case .orange: IntermediateColor.orange.rawValue
            case .yellow: IntermediateColor.yellow.rawValue
            case .green: IntermediateColor.green.rawValue
            case .mint: IntermediateColor.mint.rawValue
            case .teal: IntermediateColor.teal.rawValue
            case .cyan: IntermediateColor.cyan.rawValue
            case .blue: IntermediateColor.blue.rawValue
            case .indigo: IntermediateColor.indigo.rawValue
            case .purple: IntermediateColor.purple.rawValue
            case .pink: IntermediateColor.pink.rawValue
            case .brown: IntermediateColor.brown.rawValue
            default: IntermediateColor.blue.rawValue
            }
        }
    }
}
