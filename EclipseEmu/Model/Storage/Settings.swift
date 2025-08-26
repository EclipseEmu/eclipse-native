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


@MainActor
final class Settings: ObservableObject {
    let encoder: JSONEncoder = .init()
    let decoder: JSONDecoder = .init()
    
    static let defaults = UserDefaults.standard
    
    typealias ControlsSystemsProfiles<ProfileObject: ControlsProfileObject> = [System : ObjectBox<ProfileObject>]

    @AppStorage(Settings.Keys.listSortingMethod.rawValue, store: Settings.defaults)
    var listSortMethod: GameListSortingMethod = .name
    @AppStorage(Settings.Keys.listSortingDirection.rawValue, store: Settings.defaults)
    var listSortDirection: GameListSortingDirection = .ascending

    @AppStorage(Settings.Keys.volume.rawValue, store: Settings.defaults)
    var volume: Double = 0.5
    @AppStorage(Settings.Keys.ignoreSilentMode.rawValue, store: Settings.defaults)
    var ignoreSilentMode: Bool = true
    
    @Published var controlsProfilesLoading: Bool = true
#if canImport(UIKit)
    @Published var touchSystemProfiles: ControlsSystemsProfiles<TouchProfileObject> = [:] {
        didSet {
            guard let encoded = try? encoder.encode(touchSystemProfiles) else { return }
            Self.defaults.set(encoded, forKey: Self.Keys.touchSystemProfiles.rawValue)
        }
    }
#endif
    @Published var keyboardSystemProfiles: ControlsSystemsProfiles<KeyboardProfileObject> = [:] {
        didSet {
            guard let encoded = try? encoder.encode(keyboardSystemProfiles) else { return }
            Self.defaults.set(encoded, forKey: Self.Keys.keyboardSystemProfiles.rawValue)
        }
    }
    
    @Published var controllerSystemProfiles: ControlsSystemsProfiles<ControllerProfileObject> = [:] {
        didSet {
            guard let encoded = try? encoder.encode(controllerSystemProfiles) else { return }
            Self.defaults.set(encoded, forKey: Self.Keys.controllerSystemProfiles.rawValue)
        }
    }

    enum Keys: String, RawRepresentable, CaseIterable {
        case listSortingMethod = "games.sortingMethod"
        case listSortingDirection = "games.sortingDirection"

        case registeredCores = "games.cores"
        
        case volume = "audio.volume"
        case ignoreSilentMode = "audio.ignoreSilentMode"
        
#if canImport(UIKit)
        case touchSystemProfiles = "controls.profiles.touch"
#endif
        case keyboardSystemProfiles = "controls.profiles.keyboards"
        case controllerSystemProfiles = "controls.profiles.controller"
    }
    
    static func getSortDirection() -> GameListSortingDirection {
        return GameListSortingDirection(rawValue: UserDefaults.standard.integer(forKey: Self.Keys.listSortingDirection.rawValue)) ?? .descending
    }

    static func getSortMethod() -> GameListSortingMethod {
        return GameListSortingMethod(rawValue: UserDefaults.standard.integer(forKey: Self.Keys.listSortingMethod.rawValue)) ?? .name
    }
    
    func persistenceReady(_ persistence: Persistence) {
        decoder.attachPersistence(persistence: persistence)
#if canImport(UIKit)
        if
            let touchData = UserDefaults.standard.data(forKey: Self.Keys.touchSystemProfiles.rawValue),
            let touch = try? decoder.decode(ControlsSystemsProfiles<TouchProfileObject>.self, from: touchData)
        {
            self.touchSystemProfiles = touch
        }
#endif
        
        if
            let keyboardData = UserDefaults.standard.data(forKey: Self.Keys.keyboardSystemProfiles.rawValue),
            let keyboard = try? decoder.decode(ControlsSystemsProfiles<KeyboardProfileObject>.self, from: keyboardData)
        {
            self.keyboardSystemProfiles = keyboard
        }
        
        if
            let controllerData = UserDefaults.standard.data(forKey: Self.Keys.controllerSystemProfiles.rawValue),
            let controller = try? decoder.decode(ControlsSystemsProfiles<ControllerProfileObject>.self, from: controllerData)
        {
            self.controllerSystemProfiles = controller
        }
        controlsProfilesLoading = false
    }
    
    func reset() {
        for key in Keys.allCases {
            UserDefaults.standard.removeObject(forKey: key.rawValue)
        }
    }
}
