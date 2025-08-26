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
    
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        controllerID: String,
        system: System,
        game: GameObject? = nil,
        profile: ControllerProfileObject? = nil
    ) -> Self {
        let model: Self = context.create()
        model.controllerID = controllerID
        model.system = system
        model.game = game
        model.profile = profile
        return model
    }
}
