import Foundation
import CoreImage
import CoreData
import OSLog
import EclipseKit

struct EmulationData {
    let romPath: URL
    let savePath: URL
    let cheats: [OwnedCheat]

    struct OwnedCheat: Identifiable, Equatable, Hashable {
        let id: ObjectIdentifier
        let code: String?
        let enabled: Bool
        let label: String?
        let priority: Int16
        let type: String?

        init(cheat: Cheat) {
            self.id = cheat.id
            self.code = cheat.code
            self.enabled = cheat.enabled
            self.label = cheat.label
            self.priority = cheat.priority
            self.type = cheat.type
        }
    }
}

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

    // MARK: Games

    func createGame(name: String, system: GameSystem, romPath: URL, romExtension: String?) async throws(GameError) {
        guard romPath.startAccessingSecurityScopedResource() else {
            throw GameError.failedToAccessSecurityScopedResource
        }

        defer { romPath.stopAccessingSecurityScopedResource() }

        let sha1: String
        do {
            sha1 = try await FileSystem.shared.sha1(for: romPath)
        } catch {
            throw .files(error)
        }
        let info: OpenVGDBItem? = if let openvgdb = try? OpenVGDB() {
            (try? await openvgdb.get(sha1: sha1, system: system))
        } else {
            nil
        }

        let game = Game(
            uuid: UUID(),
            name: info?.name ?? name,
            system: system,
            sha1: sha1,
            romExtension: romExtension,
            saveExtension: nil,
            boxart: nil
        )

        objectContext.insert(game)

        if let boxartUrl = info?.cover {
            game.boxart = try? await self.createImage(remote: boxartUrl)
        }

        try? await FileSystem.shared.copy(from: .other(romPath), to: game.romPath)

        do {
            try objectContext.saveIfNeeded()
        } catch {
            throw .persistence(error)
        }
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

    // MARK: Save States

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

// MARK: Images

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
            game.boxart = try await self.createImage(remote: url)
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
            game.boxart = try await createImage(copy: url)
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

// MARK: Tags

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

    func update(tag: ObjectBox<Tag>, name: String, color: TagColor) throws(PersistenceError) {
        let tag = try tag.get(in: objectContext)
        tag.name = name
        tag.color = color.rawValue
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

// MARK: Cheats

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

    func reorderCheatPriority(cheats: [ObjectBox<Cheat>]) throws(PersistenceError) {
        for (index, box) in cheats.enumerated() {
            let cheat = try box.get(in: objectContext)
            cheat.priority = Int16(truncatingIfNeeded: index)
        }
        try objectContext.saveIfNeeded()
    }
}
