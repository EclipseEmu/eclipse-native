import CoreData

extension Cheat {
    convenience init(
        name: String,
        code: String,
        format: String,
        isEnabled: Bool,
        for game: Game?
    ) {
        self.init(entity: Cheat.entity(), insertInto: nil)
        self.label = name
        self.type = format
        self.code = code
        self.enabled = isEnabled
        self.priority = Int16.max
        self.game = game
    }
}
