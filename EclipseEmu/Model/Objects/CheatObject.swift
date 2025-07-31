import CoreData

extension CheatObject {
    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        name: String,
        code: String,
        format: String,
        isEnabled: Bool,
        game: GameObject? = nil
    ) -> Self {
        let model: Self = context.create()
        model.label = name
        model.type = format
        model.code = code
        model.enabled = isEnabled
        model.priority = Int16.max
        model.game = game
        return model
    }
}
