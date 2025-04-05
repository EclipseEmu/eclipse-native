import Foundation
import CoreImage
import CoreData
import OSLog
import EclipseKit

struct GameCreationInfo: Sendable {
    let uuid: UUID
    let name: String
    let system: GameSystem
    let sha1: String
    let cover: FileSystemPath?
    let romExtension: String?

    init(id: UUID, name: String, system: GameSystem, cover: FileSystemPath?, sha1: String, romExtension: String?) {
        self.uuid = id
        self.name = name
        self.system = system
        self.sha1 = sha1
        self.cover = cover
        self.romExtension = romExtension
    }
}

enum GameCreationError: LocalizedError {
    case notFileURL
    case unknownSystem
    case openvgdbError(OpenVGDBError)
    case hashingFailed(FileSystemError)
    case copyFileError(FileSystemError)
    case persistenceError(PersistenceError)
}

struct GameCreationFailure {
    let url: URL
    let error: GameCreationError
}

typealias GameCreationResult = (URL, Result<GameCreationInfo, GameCreationError>)

final actor ObjectActor {
    nonisolated let fileSystem: FileSystem
    private let objectContext: NSManagedObjectContext
    private let objectExecutor: ObjectActorSerialExecutor
    public nonisolated let unownedExecutor: UnownedSerialExecutor

    init(objectContext: NSManagedObjectContext, fileSystem: FileSystem) {
        self.objectContext = objectContext
        self.objectExecutor = ObjectActorSerialExecutor(objectContext: objectContext)
        self.unownedExecutor = objectExecutor.asUnownedSerialExecutor()
        self.fileSystem = fileSystem
    }

    func rename<T>(_ box: ObjectBox<T>, to newName: String) throws(PersistenceError) where T: RenameableObject {
        let object = try box.get(in: objectContext)
        Logger.coredata.info("renaming \(object.objectID)")
        object.rename(to: newName)
        try objectContext.saveIfNeeded()
    }

    func delete<T>(_ box: ObjectBox<T>) throws(PersistenceError) where T: NSManagedObject {
        let object = try box.get(in: objectContext)
        Logger.coredata.info("deleting \(object.objectID)")
        objectContext.delete(object)
        try objectContext.saveIfNeeded()
    }

    func deleteMany<T>(_ items: [ObjectBox<T>]) throws(PersistenceError) where T: NSManagedObject {
        for box in items {
            guard let object = box.tryGet(in: objectContext) else { continue }
            Logger.coredata.info("deleting \(object.objectID)")
            objectContext.delete(object)
        }
        try objectContext.saveIfNeeded()
    }
}

// MARK: - Games

extension ObjectActor {
    nonisolated func createGames(for files: [URL]) async throws(GameCreationError) -> [GameCreationFailure] {
        let openvgdb: OpenVGDB
        do {
            openvgdb = try OpenVGDB()
        } catch {
            throw .openvgdbError(error)
        }

        let gameResults = await withTaskGroup(of: GameCreationResult.self) { group in
            for file in files {
                group.addTask {
                    await self.createGame(from: file, db: openvgdb)
                }
            }

            return await group.reduce(into: [GameCreationResult]()) { $0.append($1) }
        }

        return try await self.createGameObjects(for: gameResults)
    }

    private nonisolated func createGame(from file: URL, db: OpenVGDB?) async -> GameCreationResult {
        guard file.isFileURL else { return (file, .failure(.notFileURL)) }

        let doStopAccessing = file.startAccessingSecurityScopedResource()
        defer {
            if doStopAccessing {
                file.stopAccessingSecurityScopedResource()
            }
        }

        let contentType = try? file.resourceValues(forKeys: [.contentTypeKey]).contentType
        guard let system = contentType.map(GameSystem.init(fileType:)), system != .unknown else {
            return (file, .failure(.unknownSystem))
        }

        // Hash the game
        let sha1: String
        do {
            sha1 = try await fileSystem.sha1(for: file)
        } catch {
            return (file, .failure(.hashingFailed(error)))
        }

        let fullFileName = file.lastPathComponent
        let (fileName, romExtension) = fullFileName.splitOnce(separator: ".")
        let romExt = romExtension.map({ String($0) })

        let id = UUID()
        var name: String = String(fileName)
        var coverUrl: URL? = nil

        // Get the game info from OpenVGDB
        do {
            if let db, let entry = try await db.get(sha1: sha1, system: system) {
                name = entry.name
                coverUrl = entry.cover
            } else {
                Logger.coredata.warning("no game info found for \(sha1)")
            }
        } catch {
            Logger.coredata.warning("failed to get game info for \(sha1): \(error.localizedDescription)")
        }

        // Copy the ROM file and download the cover art
        var coverPath: FileSystemPath? = nil
        do {
            if let coverUrl {
                try await copyRom(from: file, for: sha1, with: romExt)
                coverPath = await downloadCover(for: id, cover: coverUrl)
            } else {
                try await copyRom(from: file, for: sha1, with: romExt)
            }
        } catch {
            return (file, .failure(error))
        }

        return (file, .success(GameCreationInfo(
            id: id,
            name: name,
            system: system,
            cover: coverPath,
            sha1: sha1,
            romExtension: romExt
        )))
    }

    private nonisolated func copyRom(
        from file: URL,
        for sha1: String,
        with fileExtension: String?
    ) async throws(GameCreationError) {
        do {
            try await fileSystem.copy(from: .other(file), to: .rom(fileName: sha1, fileExtension: fileExtension))
        } catch .fileWriteFileExists {
            // noop: means we don't actually need to copy (unless there's a hash collision - unlikely)
        } catch {
            throw .copyFileError(error)
        }
    }

    private nonisolated func downloadCover(for id: UUID, cover: URL) async -> FileSystemPath? {
        do {
            let path = FileSystemPath.image(fileName: id, fileExtension: cover.fileExtension())
            try await fileSystem.download(from: cover, to: path)
            return path
        } catch {
            return nil
        }
    }

    private func createGameObjects(for results: [GameCreationResult]) throws(GameCreationError) -> [GameCreationFailure] {
        var failed: [GameCreationFailure] = []
        for (file, result) in results {
            switch result {
            case .success(let info):
                let game = Game(
                    name: info.name,
                    system: info.system,
                    sha1: info.sha1,
                    romExtension: info.romExtension,
                    saveExtension: ".sav",
                    cover: nil
                )
                objectContext.insert(game)
                if case .image(fileName: let uuid, fileExtension: let fileExtension) = info.cover {
                    let cover = ImageAsset(id: uuid, fileExtension: fileExtension)
                    objectContext.insert(cover)
                    game.cover = cover
                }
                break
            case .failure(let error):
                failed.append(.init(url: file, error: error))
            }
        }

        do {
            try self.objectContext.saveIfNeeded()
        } catch {
            throw .persistenceError(error)
        }

        return failed
    }

    func canDeleteRom(sha1: String) -> Bool {
        let request = Game.fetchRequest()
        request.fetchLimit = 2
        request.predicate = NSPredicate(format: "sha1 == %@", sha1)
        request.includesPropertyValues = false
        request.includesSubentities = false
        let count = (try? objectContext.count(for: request)) ?? 0
        return count < 2
    }

    func updateDatePlayed(game: ObjectBox<Game>) throws(GameError) {
        do {
            let game = try game.get(in: objectContext)
            game.datePlayed = .now
            try objectContext.saveIfNeeded()
        } catch {
            throw .persistence(error)
        }
    }
}

// MARK: - Save States

extension ObjectActor {
    nonisolated func createSaveState(
        isAuto: Bool,
        for game: ObjectBox<Game>,
        with core: GameCoreCoordinator
    ) async throws(SaveStateError) {
        let id = UUID()
        let saveStatePath = self.fileSystem.url(for: .saveState(fileName: id, fileExtension: nil))

        guard await core.saveState(to: saveStatePath) else {
            throw SaveStateError.failedToCreateSaveState
        }

        do {
            let imageID = UUID()
            let preview = await core.screenshot()
            var wroteImage = false

            do {
                try await fileSystem.writeJPEG(of: preview, to: .image(fileName: imageID, fileExtension: "jpeg"))
                wroteImage = true
            } catch {}

            try await upsertSaveState(
                id: id,
                isAuto: isAuto,
                game: game,
                previewID: imageID,
                wroteImage: wroteImage
            )
        } catch {
            throw .persistence(error)
        }
    }

    private func upsertSaveState(
        id: UUID,
        isAuto: Bool,
        game: ObjectBox<Game>,
        previewID: UUID,
        wroteImage: Bool
    ) async throws(PersistenceError) {
        let game = try game.get(in: objectContext)

        let request = SaveState.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "(isAuto == true) AND (game == %@)", game)

        if isAuto, let item = try? objectContext.fetch(request).first {
            objectContext.delete(item)
        }

        let saveState = SaveState(
            id: id,
            isAuto: isAuto,
            stateExtension: nil,
            preview: nil,
            game: nil
        )

        objectContext.insert(saveState)
        if wroteImage {
            let asset = ImageAsset(id: previewID, fileExtension: "jpeg")
            objectContext.insert(asset)
            saveState.preview = asset
        }

        saveState.game = game
        try objectContext.saveIfNeeded()
    }
}

// MARK: - Images

extension ObjectActor {
    private func createImage(copy sourceUrl: URL) async throws(FileSystemError) -> ImageAsset {
        let asset = ImageAsset(fileExtension: sourceUrl.fileExtension())
        try await fileSystem.overwrite(copying: .other(sourceUrl), to: asset.path)
        objectContext.insert(asset)
        return asset
    }

    private func createImage(remote: URL) async throws(FileSystemError) -> ImageAsset {
        let asset = ImageAsset(fileExtension: remote.fileExtension())
        try await fileSystem.download(from: remote, overwriting: asset.path)
        objectContext.insert(asset)
        return asset
    }

    func replaceCoverArt(game box: ObjectBox<Game>, fromRemote url: URL) async throws(ImageAssetError) {
        do {
            let game = try box.get(in: objectContext)
            game.cover = try await self.createImage(remote: url)
            try objectContext.saveIfNeeded()
        } catch let error as PersistenceError {
            throw .persistence(error)
        } catch let error as FileSystemError {
            throw .files(error)
        } catch {
            unreachable()
        }
    }

    func replaceCoverArt(game box: ObjectBox<Game>, copying url: URL) async throws(ImageAssetError) {
        do {
            let game = try box.get(in: objectContext)
            game.cover = try await createImage(copy: url)
            try objectContext.saveIfNeeded()
        } catch let error as PersistenceError {
            throw .persistence(error)
        } catch let error as FileSystemError {
            throw .files(error)
        } catch {
            unreachable()
        }
    }
}

// MARK: - Tags

extension ObjectActor {
    func setTags<S: Sequence>(_ tags: S, for game: ObjectBox<Game>) throws(PersistenceError)
    where S.Element == ObjectBox<Tag>
    {
        let game = try game.get(in: objectContext)
        let set = tags.compactMap { $0.tryGet(in: objectContext) }
        game.tags = NSSet(array: set)
        try objectContext.saveIfNeeded()
    }

    func createTag(name: String, color: TagColor) throws(PersistenceError) {
        let tag = Tag(name: name, color: color)
        objectContext.insert(tag)
        try objectContext.saveIfNeeded()
    }

    func toggle(for tag: ObjectBox<Tag>, state: Bool, games: [ObjectBox<Game>]) throws(PersistenceError) {
        let tag = try tag.get(in: objectContext)
        if state {
            for game in games {
                let game = try game.get(in: objectContext)
                tag.addToGames(game)
            }
        } else {
            for game in games {
                let game = try game.get(in: objectContext)
                tag.removeFromGames(game)
            }
        }
        try objectContext.saveIfNeeded()
    }

    func update(tag: ObjectBox<Tag>, name: String, color: TagColor) throws(PersistenceError) {
        let tag = try tag.get(in: objectContext)
        tag.name = name
        tag.color = color
        try objectContext.saveIfNeeded()
    }

    func toggleTag(tag: ObjectBox<Tag>, for game: ObjectBox<Game>) throws(PersistenceError) {
        let tag = try tag.get(in: objectContext)
        let game = try game.get(in: objectContext)

        if game.tags?.contains(tag) ?? false {
            tag.removeFromGames(game)
        } else {
            tag.addToGames(game)
        }

        try objectContext.saveIfNeeded()
    }
}

// MARK: - Cheats

extension ObjectActor {
    func createCheat(
        name: String,
        code: String,
        format: String,
        isEnabled: Bool,
        for game: ObjectBox<Game>
    ) throws(PersistenceError) {
        let game = try game.get(in: objectContext)
        let cheat = Cheat(
            name: name,
            code: code,
            format: format,
            isEnabled: isEnabled,
            for: nil
        )
        objectContext.insert(cheat)
        cheat.game = game
        try objectContext.saveIfNeeded()
    }

    func update(
        cheat: ObjectBox<Cheat>,
        name: String,
        code: String,
        format: String,
        enabled: Bool
    ) throws(PersistenceError) {
        let cheat = try cheat.get(in: objectContext)
        cheat.label = name
        cheat.code = code
        cheat.type = format
        cheat.enabled = enabled
        try objectContext.saveIfNeeded()
    }

    func setCheatStatus(cheat: ObjectBox<Cheat>, isEnabled: Bool) throws(PersistenceError) {
        let cheat = try cheat.get(in: objectContext)
        cheat.enabled = isEnabled
        try objectContext.saveIfNeeded()
    }

    func reorderCheatPriority(cheats: [ObjectBox<Cheat>]) throws(PersistenceError) {
        for (index, box) in cheats.enumerated() {
            let cheat = try box.get(in: objectContext)
            cheat.priority = Int16(truncatingIfNeeded: index)
        }
        try objectContext.saveIfNeeded()
    }
}
