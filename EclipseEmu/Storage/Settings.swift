import SwiftUI
import EclipseKit
import mGBAEclipseCore

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

@MainActor
final class Settings: ObservableObject {
    private static let defaults = UserDefaults.standard
    private static let jsonDecoder: JSONDecoder = JSONDecoder()
    private static let jsonEncoder: JSONEncoder = JSONEncoder()

    @AppStorage(Settings.Keys.listSortingMethod.rawValue, store: Settings.defaults)
    var listSortMethod: GameListSortingMethod = .name
    @AppStorage(Settings.Keys.listSortingDirection.rawValue, store: Settings.defaults)
    var listSortDirection: GameListSortingDirection = .ascending

    @AppStorage(Settings.Keys.registeredCores.rawValue, store: Settings.defaults)
    private var rawRegisteredCores: Data?
    @AppStorage(Settings.Keys.volume.rawValue, store: Settings.defaults)
    var volume: Double = 0.5
    @AppStorage(Settings.Keys.ignoreSilentMode.rawValue, store: Settings.defaults)
    var ignoreSilentMode: Bool = true
    @AppStorage(Settings.Keys.touchControlsOpacity.rawValue)
    var touchControlsOpacity: Double = 0.6

    /// A dictionary of Systems -> Core IDs
    var registeredCores: [GameSystem : String] {
        get {
            guard
                let rawRegisteredCores,
                let cores = try? Self.jsonDecoder.decode([GameSystem : String].self, from: rawRegisteredCores)
            else {
                return [
                    .gba : String(cString: mGBACoreInfo.id)
                ]
            }
            return cores
        }
        set {
            rawRegisteredCores = try? Self.jsonEncoder.encode(newValue)
        }
    }

    enum Keys: String, RawRepresentable, CaseIterable {
        case listSortingMethod = "games.sortingMethod"
        case listSortingDirection = "games.sortingDirection"

        case registeredCores = "games.cores"

        case volume = "audio.volume"
        case ignoreSilentMode = "audio.ignoreSilentMode"
        case touchControlsOpacity = "controls.touchControlsOpacity"
    }

    static func getSortDirection() -> GameListSortingDirection {
        return GameListSortingDirection(rawValue: UserDefaults.standard.integer(forKey: Self.Keys.listSortingDirection.rawValue)) ?? .descending
    }

    static func getSortMethod() -> GameListSortingMethod {
        return GameListSortingMethod(rawValue: UserDefaults.standard.integer(forKey: Self.Keys.listSortingMethod.rawValue)) ?? .name
    }

    func reset() {
        for key in Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
