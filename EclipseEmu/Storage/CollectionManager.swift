import Foundation
import CoreData

enum CollectionManager {
    enum Failure {}

    static func listRequest(collection: GameCollection) -> NSFetchRequest<Game> {
        let request = Game.fetchRequest()
        request.predicate = NSPredicate(format: "%K CONTAINS %@", #keyPath(Game.collections), collection)
        return request
    }

    static func searchPredicate(collection: GameCollection, query: String) -> NSPredicate {
        return query.isEmpty
        ? NSPredicate(format: "%K CONTAINS %@", #keyPath(Game.collections), collection)
        : NSPredicate(format: "(%K CONTAINS %@) AND (name CONTAINS %@)", #keyPath(Game.collections), collection, query)
    }

    static func rename(collection: GameCollection, name: String, in persistence: PersistenceCoordinator) {
        collection.name = name
        persistence.save()
    }

    static func create(
        name: String,
        icon: GameCollection.Icon,
        color: GameCollection.Color,
        in persistence: PersistenceCoordinator
    ) {
        let collection = GameCollection(context: persistence.context)
        collection.name = name
        collection.icon = icon
        collection.color = color.rawValue
        persistence.save()
    }

    static func update(
        _ collection: GameCollection,
        name: String,
        icon: GameCollection.Icon,
        color: GameCollection.Color,
        in persistence: PersistenceCoordinator
    ) {
        collection.name = name
        collection.icon = icon
        collection.color = color.rawValue
        persistence.save()
    }

    static func updateGame(for game: Game, collections: Set<GameCollection>, in persistence: PersistenceCoordinator) {
        game.collections = collections as NSSet
        persistence.saveIfNeeded()
    }

    static func delete(_ collection: GameCollection, in persistence: PersistenceCoordinator) {
        persistence.context.delete(collection)
        persistence.saveIfNeeded()
    }
}
