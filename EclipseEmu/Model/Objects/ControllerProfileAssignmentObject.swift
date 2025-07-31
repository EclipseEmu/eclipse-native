import CoreData
import EclipseKit

extension ControllerProfileAssignmentObject {
    var system: System {
        get {
            System(rawValue: UInt16(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int16(newValue.rawValue)
        }
    }
}
