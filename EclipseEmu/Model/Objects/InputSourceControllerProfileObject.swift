import CoreData
import EclipseKit

extension InputSourceControllerProfileObject {
    var system: GameSystem {
        get {
            GameSystem(rawValue: UInt32(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int32(newValue.rawValue)
        }
    }

    var version: InputSourceControllerVersion? {
        get {
            InputSourceControllerVersion(rawValue: rawVersion)
        }
        set {
            self.rawVersion = newValue?.rawValue ?? 0
        }
    }
}
