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
    
    static func create(isAuto: Bool, for game: Game, with coreCoordinator: GameCoreCoordinator, in persistence: PersistenceCoordinator) async throws {
        let saveState = SaveState(context: persistence.context)
        saveState.id = UUID()
        saveState.date = .now
        saveState.isAuto = isAuto
        saveState.game = game
        
        let saveStatePath = saveState.path(in: persistence)
        guard await coreCoordinator.saveState(to: saveStatePath) else {
            throw Failure.failedToCreateSaveState
        }
        
        // delete older auto save states
        if isAuto {
            let deleteFetchRequest = SaveState.fetchRequest()
            deleteFetchRequest.predicate = NSPredicate(format: "(isAuto == true) AND (game == %@) AND (id != %@)", game, saveState.id as NSUUID)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetchRequest as! NSFetchRequest<any NSFetchRequestResult>)
            deleteRequest.resultType = .resultTypeStatusOnly
            let _ = try? persistence.context.execute(deleteRequest) as? NSBatchDeleteResult
        }
        
        persistence.save()
    }
    
    static func rename(_ saveState: SaveState, to newName: String, in persistence: PersistenceCoordinator) {
        saveState.name = newName
        persistence.save()
    }
    
    static func delete(_ saveState: SaveState, in persistence: PersistenceCoordinator) throws {
        persistence.context.delete(saveState)
        persistence.save()
    }
}
