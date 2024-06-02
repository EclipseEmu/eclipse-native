import CoreData
import EclipseKit
import Foundation

enum GameManager {
    static var openvgdb: OpenVGDB?

    enum Failure: LocalizedError {
        case failedToAccessSecurityScopedResource
        case failedToGetRomPath
        case failedToGetReadPermissions
        case unknownFileType
    }

    struct EmulationData {
        let romPath: URL
        let savePath: URL
        let cheats: Set<Cheat>
    }

    static func getOpenVGDB() async throws -> OpenVGDB {
        if let openvgdb {
            return openvgdb
        } else {
            self.openvgdb = try await OpenVGDB()
            return self.openvgdb!
        }
    }

    static func recentlyPlayedRequest() -> NSFetchRequest<Game> {
        let request = Game.fetchRequest()
        request.fetchLimit = 10
        request.predicate = NSPredicate(format: "datePlayed != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Game.datePlayed, ascending: false)]
        return request
    }

    static func insert(
        name: String,
        system: GameSystem,
        romPath: URL,
        romExtension: String?,
        in persistence: PersistenceCoordinator
    ) async throws {
        guard romPath.startAccessingSecurityScopedResource() else { throw Failure.failedToAccessSecurityScopedResource }
        defer { romPath.stopAccessingSecurityScopedResource() }

        let romData = try await Data(asyncContentsOf: romPath)
        let md5 = await withUnsafeBlockingContinuation { continuation in
            let digest = MD5Hasher().hash(data: romData)
            continuation.resume(returning: digest.hexString())
        }

        let info: OpenVGDB.Item? = if let openvgdb = try? await self.getOpenVGDB() {
            (try? await openvgdb.get(md5: md5, system: system))?.first
        } else {
            nil
        }

        let game = Game(context: persistence.context)
        game.id = UUID()
        game.name = info?.name ?? name
        game.system = system
        game.dateAdded = Date.now
        game.datePlayed = nil
        game.md5 = md5

        if let boxartUrl = info?.boxart {
            game.boxart = try? await ImageAssetManager.create(remote: boxartUrl, in: persistence, save: false)
        }

        try persistence.writeFile(path: game.romPath(in: persistence), contents: romData)

        persistence.save()
    }

    static func updateDatePlayed(for game: Game, in persistence: PersistenceCoordinator) {
        game.datePlayed = .now
        persistence.save()
    }

    static func delete(_ game: Game, in persistence: PersistenceCoordinator) async throws {
        persistence.context.delete(game)
        persistence.save()
    }

    static func rename(_ game: Game, to newName: String, in persistence: PersistenceCoordinator) {
        game.name = newName
        persistence.saveIfNeeded()
    }

    /// - Returns: Data needed by the emulator, including paths and cheats.
    static func emulationData(for game: Game, in persistence: PersistenceCoordinator) throws -> Self.EmulationData {
        let romPath = game.romPath(in: persistence)
        let savePath = game.savePath(in: persistence)
        let cheats: Set<Cheat> = (game.cheats as? Set<Cheat>) ?? Set()
        return .init(romPath: romPath, savePath: savePath, cheats: cheats)
    }
}
