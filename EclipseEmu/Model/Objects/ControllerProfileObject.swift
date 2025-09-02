import CoreData
import EclipseKit

extension ControllerProfileObject: InputSourceProfileObject {
    var system: System {
        get {
            System(rawValue: UInt16(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int16(newValue.rawValue)
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
    
    static func navigationDestination(_ object: ControllerProfileObject) -> Destination {
        .controllerProfile(object)
    }
}
