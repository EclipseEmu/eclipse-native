import CoreData

enum CheatManager {
    static func listRequest(for game: Game) -> NSFetchRequest<Cheat> {
        let request = Cheat.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
        return request
    }

    static func update(cheat: Cheat, in persistence: PersistenceCoordinator) {
        persistence.save()
    }

    static func create(
        name: String,
        code: String,
        format: String,
        isEnabled: Bool,
        for game: Game,
        in persistence: PersistenceCoordinator
    ) throws {
        let cheat = Cheat(context: persistence.context)
        cheat.label = name
        cheat.type = format
        cheat.code = code
        cheat.enabled = isEnabled
        cheat.priority = Int16.max
        cheat.game = game
        persistence.save()
    }

    @inlinable
    static func delete(cheat: Cheat, in persistence: PersistenceCoordinator, save: Bool) throws {
        persistence.context.delete(cheat)
        if save {
            persistence.save()
        }
    }
}
