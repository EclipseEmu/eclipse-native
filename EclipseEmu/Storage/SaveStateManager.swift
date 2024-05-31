import CoreData

enum SaveStateManager {
    enum Failure: LocalizedError {
        case failedToCreateSaveState
    }

    static func listRequest(for game: Game, limit: Int?) -> NSFetchRequest<SaveState> {
        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
        if let limit {
            request.fetchLimit = limit
        }
        return request
    }

    static func create(
        isAuto: Bool,
        for game: Game,
        with coreCoordinator: GameCoreCoordinator,
        in persistence: PersistenceCoordinator
    ) async throws {
        var saveState: SaveState
        if isAuto {
            let request = SaveState.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "(isAuto == true) AND (game == %@)", game)
            if let item = try? persistence.context.fetch(request).first {
                saveState = item
                if let preview = saveState.preview {
                    persistence.context.delete(preview)
                }
            } else {
                saveState = SaveState(context: persistence.context)
            }
        } else {
            saveState = SaveState(context: persistence.context)
        }

        saveState.id = UUID()
        saveState.date = .now
        saveState.isAuto = isAuto
        saveState.game = game

        let screenshot = await coreCoordinator.screenshot()
        saveState.preview = try? ImageAssetManager.create(from: screenshot, in: persistence, save: false)

        let saveStatePath = saveState.path(in: persistence)
        guard await coreCoordinator.saveState(to: saveStatePath) else {
            throw Failure.failedToCreateSaveState
        }

        persistence.save()
    }

    static func rename(_ saveState: SaveState, to newName: String, in persistence: PersistenceCoordinator) {
        saveState.name = newName
        persistence.save()
    }

    static func delete(_ saveState: SaveState, in persistence: PersistenceCoordinator) {
        persistence.context.delete(saveState)
    }
}
