import Foundation
import CoreImage
import CoreData
import OSLog
import EclipseKit

enum GameError: LocalizedError {
    case failedToAccessSecurityScopedResource
    case failedToGetRomPath
    case failedToGetReadPermissions
    case unknownFileType
}

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

final actor LibraryActor {
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
        object.rename(to: newName)
        try objectContext.saveIfNeeded()
    }

    func delete<T>(_ box: ObjectBox<T>) throws(PersistenceError) where T: NSManagedObject {
        let item = try box.get(in: objectContext)
        Logger.coredata.info("deleting \(item.objectID)")
        objectContext.delete(item)
        try objectContext.saveIfNeeded()
    }

    func deleteMany<T>(_ items: [ObjectBox<T>]) throws(PersistenceError) where T: NSManagedObject {
        for box in items {
            guard let item = box.tryGet(in: objectContext) else { continue }
            Logger.coredata.info("deleting \(item.objectID)")
            objectContext.delete(item)
        }
        try objectContext.saveIfNeeded()
    }
}

// MARK: Games

extension LibraryActor {
    func createGame(name: String, system: GameSystem, romPath: URL, romExtension: String?) async throws {
        guard romPath.startAccessingSecurityScopedResource() else {
            throw GameError.failedToAccessSecurityScopedResource
        }

        defer { romPath.stopAccessingSecurityScopedResource() }

        let md5 = try await FileSystem.shared.md5(for: romPath)
        let info: OpenVGDB.Item? = if let openvgdb = try? await OpenVGDB() {
            (try? await openvgdb.get(md5: md5, system: system))?.first
        } else {
            nil
        }

        let game = Game(
            uuid: UUID(),
            name: info?.name ?? name,
            system: system,
            md5: md5,
            romExtension: romExtension,
            saveExtension: nil,
            boxart: nil
        )

        objectContext.insert(game)

        if let boxartUrl = info?.boxart {
            game.boxart = try? await self.createImage(remote: boxartUrl).tryGet(in: self.objectContext)
        }

        try? await FileSystem.shared.copy(from: .other(romPath), to: game.romPath)

        try objectContext.saveIfNeeded()
    }

    func canDeleteRom(md5: String) -> Bool {
        let request = Game.fetchRequest()
        request.fetchLimit = 2
        request.predicate = NSPredicate(format: "md5 == %@", md5)
        request.includesPropertyValues = false
        request.includesSubentities = false
        let count = (try? objectContext.count(for: request)) ?? 0
        return count < 2
    }

    func updateDatePlayed(game: ObjectBox<Game>) throws {
        let game = try game.get(in: objectContext)
        game.datePlayed = .now
        try objectContext.saveIfNeeded()
    }
}

// MARK: Save States

extension LibraryActor {
    nonisolated func createSaveState(
        isAuto: Bool,
        for game: ObjectBox<Game>,
        with core: GameCoreCoordinator
    ) async throws {
        let id = UUID()
        let saveStatePath = self.fileSystem.url(for: .saveState(fileName: id, fileExtension: nil))

        guard await core.saveState(to: saveStatePath) else {
            throw SaveStateError.failedToCreateSaveState
        }

        let imageID = UUID()
        let preview = await core.screenshot()
        var wroteImage = false
        do {
            try await fileSystem.writeJPEG(of: preview, to: .image(fileName: imageID, fileExtension: "jpeg"))
            wroteImage = true
        }

        try await upsertSaveState(
            id: id,
            isAuto: isAuto,
            game: game,
            previewID: imageID,
            wroteImage: wroteImage
        )
    }

    private func upsertSaveState(
        id: UUID,
        isAuto: Bool,
        game: ObjectBox<Game>,
        previewID: UUID,
        wroteImage: Bool
    ) async throws {
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

extension LibraryActor {
    func createImage(copy sourceUrl: URL) async throws -> ObjectBox<ImageAsset> {
        let asset = ImageAsset(fileExtension: sourceUrl.fileExtension())
        try await fileSystem.overwrite(copying: .other(sourceUrl), to: asset.path)

        objectContext.insert(asset)
        try objectContext.saveIfNeeded()
        return .init(asset)
    }

    func createImage(remote: URL) async throws -> ObjectBox<ImageAsset> {
        let asset = ImageAsset(fileExtension: remote.fileExtension())
        try await fileSystem.download(from: remote, overwriting: asset.path)

        objectContext.insert(asset)
        try objectContext.saveIfNeeded()
        return .init(asset)
    }

    func replaceCoverArt(game: ObjectBox<Game>, fromRemote url: URL) async throws {
        let game = try game.get(in: objectContext)
        let boxart = try await self.createImage(remote: url).get(in: objectContext)
        game.boxart = boxart
        try objectContext.saveIfNeeded()
    }

    func replaceCoverArt(game: ObjectBox<Game>, copying url: URL) async throws {
        let game = try game.get(in: objectContext)
        let boxart = try await self.createImage(copy: url).get(in: objectContext)
        game.boxart = boxart
        try objectContext.saveIfNeeded()
    }
}

// MARK: Tags

extension LibraryActor {
    func setTags<S: Sequence>(_ tags: S, for game: ObjectBox<Game>) throws where S.Element == ObjectBox<Tag> {
        let game = try game.get(in: objectContext)
        let set = tags.compactMap { $0.tryGet(in: objectContext) }
        game.tags = NSSet(array: set)
        try objectContext.saveIfNeeded()
    }

    func createTag(name: String, color: Tag.Color) throws {
        let tag = Tag(name: name, color: color)
        objectContext.insert(tag)
        try objectContext.saveIfNeeded()
    }

    func update(tag: ObjectBox<Tag>, name: String, color: Tag.Color) throws {
        let tag = try tag.get(in: objectContext)
        tag.name = name
        tag.color = color.rawValue
        try objectContext.saveIfNeeded()
    }

    func toggleTag(tag: ObjectBox<Tag>, for game: ObjectBox<Game>) throws {
        let tag = try tag.get(in: objectContext)
        let game = try game.get(in: objectContext)

        if game.tags?.contains(tag) ?? false {
            tag.removeFromGames(game)
        } else {
            tag.addToGames(game)
        }
    }
}

// MARK: Cheats

extension LibraryActor {
    func createCheat(
        name: String,
        code: String,
        format: String,
        isEnabled: Bool,
        for game: ObjectBox<Game>
    ) throws {
        let game = try game.get(in: objectContext)
        let cheat = Cheat(
            name: name,
            code: code,
            format: format,
            isEnabled: isEnabled,
            for: game
        )
        objectContext.insert(cheat)
        try objectContext.saveIfNeeded()
    }

    func update(
        cheat: ObjectBox<Cheat>,
        name: String,
        code: String,
        format: String,
        enabled: Bool
    ) throws {
        let cheat = try cheat.get(in: objectContext)
        cheat.label = name
        cheat.code = code
        cheat.type = format
        cheat.enabled = enabled
        try objectContext.saveIfNeeded()
    }

    func reorderCheatPriority(cheats: [ObjectBox<Cheat>]) throws {
        for (index, box) in cheats.enumerated() {
            let cheat = try box.get(in: objectContext)
            cheat.priority = Int16(truncatingIfNeeded: index)
        }
        try objectContext.saveIfNeeded()
    }
}
