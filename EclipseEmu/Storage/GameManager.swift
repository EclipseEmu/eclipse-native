import Foundation
import CoreData
import EclipseKit

struct GameManager {
    enum Failure: Error {
        case failedToAccessSecurityScopedResource
        case failedToGetRomPath
    }
    
    struct EmulationData {
        let romPath: URL
        let savePath: URL
        let cheats: Set<Cheat>
    }
    
    let persistence: PersistenceCoordinator
    
    init(_ persistence: PersistenceCoordinator) {
        self.persistence = persistence
    }
    
    func insert(name: String, system: GameSystem, romPath: URL, romExtension: String?) async throws {
        guard romPath.startAccessingSecurityScopedResource() else { throw Failure.failedToAccessSecurityScopedResource }
        defer { romPath.stopAccessingSecurityScopedResource() }
        
        let romData = try await Data(asyncContentsOf: romPath)
        let digest = MD5Hasher().hash(data: romData)
        let md5 = digest.hexString()
        
        let game = Game(context: persistence.context)
        game.id = UUID()
        game.name = name
        game.system = system
        game.dateAdded = Date.now
        game.datePlayed = nil
        game.md5 = md5

        try persistence.external.writeRom(for: game, data: romData)

        persistence.save()
    }
    
    func updateDatePlayed(for game: Game) {
        game.datePlayed = .now
        persistence.save()
    }
    
    func delete(game: Game) async throws {
        // determine if the rom should be deleted
        let canDeleteRom = try await persistence.context.perform {
            let request = Game.fetchRequest()
            request.fetchLimit = 2
            request.predicate = NSPredicate(format: "md5 == %@", game.md5)
            request.includesPropertyValues = false
            request.includesSubentities = false
            let count = try self.persistence.context.count(for: request)
            return count < 2
        }
        

        if canDeleteRom {
            try persistence.external.deleteRom(for: game)
        }
        
        try persistence.external.deleteSave(for: game)
        
        let saveStatePaths = try await persistence.context.perform {
            let request = SaveState.fetchRequest()
            request.predicate = NSPredicate(format: "game = %@", game)
            let saveStates = try request.execute()
            let paths = saveStates.map { persistence.external.getSaveStatePath(for: $0) }
            saveStates.forEach(persistence.context.delete(_:))
            return paths
        }
        
        for saveStatePath in saveStatePaths {
            try? persistence.external.deleteFile(path: saveStatePath)
        }
        
        persistence.context.delete(game)
    }
    
    /// Returns data needed by the emulator
    func emulationData(for game: Game) throws -> Self.EmulationData {
        let externalStorage = persistence.external
        let romPath = externalStorage.getRomPath(for: game)
        let savePath = externalStorage.getSavePath(for: game)
        let cheats: Set<Cheat> = (game.cheats as? Set<Cheat>) ?? Set()
        return .init(romPath: romPath, savePath: savePath, cheats: cheats)
    }
}
