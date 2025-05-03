import CoreData
import EclipseKit

extension InputSourceKeyboardProfileObject {
    var system: GameSystem {
        get {
            GameSystem(rawValue: UInt32(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int32(newValue.rawValue)
        }
    }

    var version: InputSourceKeyboardVersion? {
        get {
            InputSourceKeyboardVersion(rawValue: rawVersion)
        }
        set {
            self.rawVersion = newValue?.rawValue ?? 0
        }
    }
}
