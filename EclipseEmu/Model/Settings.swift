import SwiftUI
import EclipseKit

/// How games will be ordered in the list.
enum GameListSortingMethod: Int, RawRepresentable {
    case name = 0
    case dateAdded = 1
}

/// Which direction games will be ordered.
enum GameListSortingDirection: Int, RawRepresentable {
    case ascending = 0
    case descending = 1
}

final class Settings: ObservableObject {
    private static let jsonDecoder: JSONDecoder = JSONDecoder()
    private static let jsonEncoder: JSONEncoder = JSONEncoder()

    @AppStorage(Settings.Keys.volume.rawValue) var volume: Double = 0.5
    @AppStorage(Settings.Keys.listSortingMethod.rawValue) var listSortMethod: GameListSortingMethod = .name
    @AppStorage(Settings.Keys.listSortingDirection.rawValue) var listSortDirection: GameListSortingDirection = .ascending
    @AppStorage(Settings.Keys.registeredCores.rawValue) private var rawRegisteredCores: Data?

    /// A dictionary of Systems -> Core IDs
    var registeredCores: [GameSystem : String] {
        get {
            guard
                let rawRegisteredCores,
                let cores = try? Self.jsonDecoder.decode([GameSystem : String].self, from: rawRegisteredCores)
            else { return [:] }
            return cores
        }
        set {
            rawRegisteredCores = try? Self.jsonEncoder.encode(newValue)
        }
    }

    enum Keys: String, RawRepresentable {
        case volume = "audio.volume"
        case listSortingMethod = "games.sortingMethod"
        case listSortingDirection = "games.sortingDirection"
        case tabsCustomization = "layout.tabsCustomization"
        case registeredCores = "games.cores"
    }

    static func getSortDirection() -> GameListSortingDirection {
        return GameListSortingDirection(rawValue: UserDefaults.standard.integer(forKey: Self.Keys.listSortingDirection.rawValue)) ?? .descending
    }

    static func getSortMethod() -> GameListSortingMethod {
        return GameListSortingMethod(rawValue: UserDefaults.standard.integer(forKey: Self.Keys.listSortingMethod.rawValue)) ?? .name
    }
}
