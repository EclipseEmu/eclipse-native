import CoreData
import EclipseKit

extension TouchProfileObject: InputSourceProfileObject {
    var system: System {
        get {
            System(rawValue: UInt16(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int16(newValue.rawValue)
        }
    }
    
    var version: InputSourceTouchVersion? {
        get {
            InputSourceTouchVersion(rawValue: rawVersion)
        }
        set {
            self.rawVersion = newValue?.rawValue ?? 0
        }
    }
    
    static func navigationDestination(_ object: TouchProfileObject) -> Destination {
#if canImport(UIKit)
        .touchProfile(object)
#else
        unreachable()
#endif
    }
}
