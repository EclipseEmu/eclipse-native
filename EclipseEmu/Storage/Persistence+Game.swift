import Foundation
import CoreData
import EclipseKit

enum CreateGameResult {
    struct Info: Sendable {
        let md5: String
        let name: String
        let system: GameSystem
        let romPath: Files.Path
        let boxartPath: Files.Path?
    }

    case success(CreateGameResult.Info)
    case failure(originalPath: URL, error: any Error)
}

struct StartEmulationData {
    let romPath: URL
    let savePath: URL
    let cheats: Set<Cheat>
}

extension Persistence {
    /// Creates multiple game entities from the local file system.
    /// - Parameters:
    ///   - urls: A list of local file URLs to add to the library
    ///   - openvgdb: An instance of OpenVGDB to use
    ///   - persistence: An instance of the Persistance class that will be used
    /// - Returns: A list of the results of items
    func create(games urls: [URL], openvgdb: OpenVGDB?) async throws -> [CreateGameResult] {
        let results = await withTaskGroup(of: CreateGameResult.self, returning: [CreateGameResult].self) { taskGroup in
            for url in urls {
                taskGroup.addTask {
                    var romPath: Files.Path!
                    var boxartPath: Files.Path?

                    do {
                        guard url.startAccessingSecurityScopedResource() else {
                            throw PersistenceError.gameFailure(.invalidPermissions)
                        }

                        defer { url.stopAccessingSecurityScopedResource() }

                        let contentType = try? url.resourceValues(forKeys: [.contentTypeKey]).contentType
                        guard let system = contentType.map(GameSystem.init(fileType:)), system != .unknown else {
                            throw PersistenceError.gameFailure(.unknownSystem)
                        }

                        let (fileName, fileExt) = url.fileNameAndExtension()

                        let md5 = try await MD5Hasher.hash(file: url).hexString()
                        romPath = Files.Path.rom(md5, fileExt)

                        async let copyRom: () = try Files.shared.copy(from: url, to: romPath)

                        var name: String = fileName
                        if
                            let item = try? await openvgdb?.get(md5: md5, system: system).first,
                            let boxartUrl = item.boxart
                        {
                            let fileExt = boxartUrl.fileExtension()
                            boxartPath = Files.Path.image(UUID(), fileExt)
                            name = item.name
                            _ = try await (copyRom, try? Files.shared.download(from: boxartUrl, to: boxartPath!))
                        } else {
                            try await copyRom
                        }

                        return .success(.init(
                            md5: md5,
                            name: name,
                            system: system,
                            romPath: romPath!,
                            boxartPath: boxartPath
                        ))
                    } catch {
                        await Files.shared.clean(files: [romPath, boxartPath])
                        return .failure(originalPath: url, error: error)
                    }
                }
            }

            var results: [CreateGameResult] = []
            results.reserveCapacity(urls.count)
            for await result in taskGroup {
                results.append(result)
            }
            return results
        }

        do {
            try await self.perform { context in
                for result in results {
                    guard case .success(let info) = result else { continue }
                    let game = Game(context: context)
                    game.id = UUID()
                    game.name = info.name
                    game.system = info.system
                    game.md5 = info.md5
                    game.dateAdded = .now
                    game.romExtension = info.romPath.fileExtension
                    if case .image(let id, let ext) = info.boxartPath {
                        let asset = ImageAsset(context: context)
                        asset.id = id
                        asset.fileExtension = ext
                        game.boxart = asset
                    }
                }

                if context.hasChanges {
                    try context.save()
                }
            }
            return results
        } catch {
            for result in results {
                guard case .success(let info) = result else { continue }
                await Files.shared.clean(files: [info.romPath, info.boxartPath])
            }
            throw error
        }
    }
    
    @inlinable
    func rename(game: Persistence.Object<Game>, to newName: String) async throws {
        try await self.update(game) { game, _ in
            game.name = newName
        }
    }

    @inlinable
    func markPlayed(game: Persistence.Object<Game>) async throws {
        try await self.update(game) { game, _ in
            game.setPrimitiveValue(Date.now, forKey: #keyPath(Game.datePlayed))
        }
    }

    static func deleteRom(rom: Files.Path, in context: NSManagedObjectContext) throws {
        guard case .rom(let md5, _) = rom else { return }

        let request = Game.fetchRequest()
        request.predicate = NSPredicate(format: "md5 == %@", md5)
        request.includesPropertyValues = false
        request.includesSubentities = false
        let count = try context.count(for: request)

        guard count <= 1 && count > -1 else { return }

        try Files.shared.deleteSync(file: rom)
    }

    func replaceBoxart(for game: Persistence.Object<Game>, newPath: Files.Path) async throws {
        try await self.update(game) { game, context in
            game.boxart = try self.create(image: newPath, in: context)
        }
    }
}
