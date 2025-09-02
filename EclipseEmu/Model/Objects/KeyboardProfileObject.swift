import CoreData
import EclipseKit

extension KeyboardProfileObject: InputSourceProfileObject {
    var system: System {
        get {
            System(rawValue: UInt16(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int16(newValue.rawValue)
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
    
    static func navigationDestination(_ object: KeyboardProfileObject) -> Destination {
        .keyboardProfile(object)
    }
}
