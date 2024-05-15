import Foundation
import CoreData
import EclipseKit

enum GameManager {
    enum Failure: Error {
        case failedToAccessSecurityScopedResource
        case failedToGetRomPath
    }
    
    struct EmulationData {
        let romPath: URL
        let savePath: URL
        let cheats: Set<Cheat>
    }
    
    static func insert(name: String, system: GameSystem, romPath: URL, romExtension: String?, in persistence: PersistenceCoordinator) async throws {
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

        try persistence.writeFile(path: game.romPath(in: persistence), contents: romData)

        persistence.save()
    }
    
    static func updateDatePlayed(for game: Game, in persistence: PersistenceCoordinator) {
        game.datePlayed = .now
        persistence.save()
    }
    
    static func delete(game: Game, in persistence: PersistenceCoordinator) async throws {
        persistence.context.delete(game)
        persistence.save()
    }
    
    /// - Returns: Data needed by the emulator, including paths and cheats.
    static func emulationData(for game: Game, in persistence: PersistenceCoordinator) throws -> Self.EmulationData {
        let romPath = game.romPath(in: persistence)
        let savePath = game.savePath(in: persistence)
        let cheats: Set<Cheat> = (game.cheats as? Set<Cheat>) ?? Set()
        return .init(romPath: romPath, savePath: savePath, cheats: cheats)
    }
}
