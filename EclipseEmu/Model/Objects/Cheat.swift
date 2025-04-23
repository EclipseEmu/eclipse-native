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

struct Cheat: Identifiable, Equatable, Hashable {
    let id: ObjectIdentifier
    let code: String?
    let enabled: Bool
    let label: String?
    let priority: Int16
    let type: String?

    init(cheat: CheatObject) {
        self.id = cheat.id
        self.code = cheat.code
        self.enabled = cheat.enabled
        self.label = cheat.label
        self.priority = cheat.priority
        self.type = cheat.type
    }
}
