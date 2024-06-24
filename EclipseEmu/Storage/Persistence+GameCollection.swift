import CoreData
import Foundation

private extension Set where Element == Persistence.Object<GameCollection> {
    func unwrap(in context: NSManagedObjectContext) throws -> Set<GameCollection> {
        var set = Set<GameCollection>()
        for element in self {
            let element = try element.unwrap(in: context)
            set.insert(element)
        }
        return set
    }
}

extension Persistence {
    func rename(collection: Persistence.Object<GameCollection>, to newName: String) async throws {
        try await self.update(collection) { collection, _ in
            collection.name = newName
        }
    }

    func addGame(_ game: Game, to collection: GameCollection) {
        collection.addToGames(game)
    }

    func removeGame(_ game: Game, from collection: GameCollection) {
        collection.removeFromGames(game)
    }

    func setCollectionsForGame(game: Persistence.Object<Game>, collections: Set<Persistence.Object<GameCollection>>) async throws {
        try await self.update(game) { game, context in
            game.collections = try collections.unwrap(in: context) as NSSet
        }
    }
}
