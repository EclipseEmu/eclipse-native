import CoreData

extension Cheat {
    @discardableResult
    convenience init(
        insertInto context: NSManagedObjectContext,
        name: String,
        code: String,
        format: String,
        isEnabled: Bool,
        game: Game? = nil
    ) {
        self.init(context: context)
        self.label = name
        self.type = format
        self.code = code
        self.enabled = isEnabled
        self.priority = Int16.max
        self.game = game
    }
}
