import Foundation
import CoreImage
import CoreData
import OSLog
import EclipseKit

struct GameCreationInfo: Sendable {
    let uuid: UUID
    let name: String
    let system: System
    let sha1: String
    let cover: FileSystemPath?
    let romExtension: String?

    init(id: UUID, name: String, system: System, cover: FileSystemPath?, sha1: String, romExtension: String?) {
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

    init(container: NSPersistentContainer, fileSystem: FileSystem) {
        objectContext = container.newBackgroundContext()
        objectContext.automaticallyMergesChangesFromParent = true
        objectContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
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
        guard let system = contentType.map(System.init(fileType:)), system != .unknown else {
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
                let game = GameObject.create(
                    in: objectContext,
                    name: info.name,
                    system: info.system,
                    sha1: info.sha1,
                    romExtension: info.romExtension,
                    saveExtension: ".sav",
                    cover: nil
                )
                if case .image(fileName: let uuid, fileExtension: let fileExtension) = info.cover {
                    let cover = ImageAssetObject.create(in: objectContext, id: uuid, fileExtension: fileExtension)
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
        let request = GameObject.fetchRequest()
        request.fetchLimit = 2
        request.predicate = NSPredicate(format: "sha1 == %@", sha1)
        request.includesPropertyValues = false
        request.includesSubentities = false
        let count = (try? objectContext.count(for: request)) ?? 0
        return count < 2
    }

    func updateDatePlayed(game: ObjectBox<GameObject>) throws(GameError) {
        do {
            let game = try game.get(in: objectContext)
            game.datePlayed = .now
            try objectContext.saveIfNeeded()
        } catch {
            throw .persistence(error)
        }
    }

    func updateHash(_ newHash: String, for game: ObjectBox<GameObject>) throws(PersistenceError) {
        let game = try game.get(in: objectContext)
        game.sha1 = newHash
        try objectContext.saveIfNeeded()
    }
}

// MARK: - Save States

extension ObjectActor {
	nonisolated func createSaveState<Core: CoreProtocol>(
        isAuto: Bool,
        for game: ObjectBox<GameObject>,
        with coordinator: CoreCoordinator<Core>
    ) async throws(SaveStateError) {
        let id = UUID()
        let saveStatePath = self.fileSystem.url(for: .saveState(fileName: id, fileExtension: "s8"))

		do {
			try await coordinator.saveState(to: saveStatePath)
		} catch {
			throw SaveStateError.failedToCreateSaveState
		}

        do {
            let imageID = UUID()
            var wroteImage = false
			if let preview = await coordinator.screenshot() {
				do {
					try await fileSystem.writeJPEG(of: preview, to: .image(fileName: imageID, fileExtension: "jpeg"))
					wroteImage = true
				} catch {}
			}

            try await upsertSaveState(
                id: id,
                isAuto: isAuto,
                game: game,
                core: coordinator.coreID,
                previewID: imageID,
                wroteImage: wroteImage,
                fileExtension: saveStatePath.fileExtension()
            )
        } catch {
            throw .persistence(error)
        }
    }

    private func upsertSaveState(
        id: UUID,
        isAuto: Bool,
        game: ObjectBox<GameObject>,
        core: Core,
        previewID: UUID,
        wroteImage: Bool,
        fileExtension: String?
    ) async throws(PersistenceError) {
        let game = try game.get(in: objectContext)

        let request = SaveStateObject.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "(isAuto == true) AND (game == %@)", game)

        if isAuto, let item = try? objectContext.fetch(request).first {
            objectContext.delete(item)
        }

        SaveStateObject.create(
            in: objectContext,
            id: id,
            isAuto: isAuto,
            core: core,
            stateExtension: fileExtension,
            preview: wroteImage ? ImageAssetObject.create(in: objectContext, id: previewID, fileExtension: "jpeg") : nil,
            game: game
        )

        try objectContext.saveIfNeeded()
    }
}

// MARK: - Images

extension ObjectActor {
    private func createImage(copy sourceUrl: URL) async throws(FileSystemError) -> ImageAssetObject {
        let asset = ImageAssetObject.create(in: objectContext, fileExtension: sourceUrl.fileExtension())
        try await fileSystem.overwrite(copying: .other(sourceUrl), to: asset.path)
        return asset
    }

    private func createImage(remote: URL) async throws(FileSystemError) -> ImageAssetObject {
        let asset = ImageAssetObject.create(in: objectContext, fileExtension: remote.fileExtension())
        try await fileSystem.download(from: remote, overwriting: asset.path)
        return asset
    }

    func replaceCoverArt(game box: ObjectBox<GameObject>, fromRemote url: URL) async throws(ImageAssetError) {
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

    func replaceCoverArt(game box: ObjectBox<GameObject>, copying url: URL) async throws(ImageAssetError) {
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
    func setTags<S: Sequence>(_ tags: S, for game: ObjectBox<GameObject>) throws(PersistenceError)
    where S.Element == ObjectBox<TagObject>
    {
        let game = try game.get(in: objectContext)
        let set = tags.compactMap { $0.tryGet(in: objectContext) }
        game.tags = NSSet(array: set)
        try objectContext.saveIfNeeded()
    }

    func createTag(name: String, color: TagColor) throws(PersistenceError) {
        TagObject.create(in: objectContext, name: name, color: color)
        try objectContext.saveIfNeeded()
    }

    func toggle(for tag: ObjectBox<TagObject>, state: Bool, games: [ObjectBox<GameObject>]) throws(PersistenceError) {
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

    func update(tag: ObjectBox<TagObject>, name: String, color: TagColor) throws(PersistenceError) {
        let tag = try tag.get(in: objectContext)
        tag.name = name
        tag.color = color
        try objectContext.saveIfNeeded()
    }

    func toggleTag(tag: ObjectBox<TagObject>, for game: ObjectBox<GameObject>) throws(PersistenceError) {
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
        for game: ObjectBox<GameObject>
    ) throws(PersistenceError) {
        let game = try game.get(in: objectContext)
        CheatObject.create(in: objectContext, name: name, code: code, format: format, isEnabled: isEnabled, game: game)
        try objectContext.saveIfNeeded()
    }

    func update(
        cheat: ObjectBox<CheatObject>,
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

    func setCheatStatus(cheat: ObjectBox<CheatObject>, isEnabled: Bool) throws(PersistenceError) {
        let cheat = try cheat.get(in: objectContext)
        cheat.enabled = isEnabled
        try objectContext.saveIfNeeded()
    }

    func reorderCheatPriority(cheats: [ObjectBox<CheatObject>]) throws(PersistenceError) {
        for (index, box) in cheats.enumerated() {
            let cheat = try box.get(in: objectContext)
            cheat.priority = Int16(truncatingIfNeeded: index)
        }
        try objectContext.saveIfNeeded()
    }
}

// MARK: Controls

enum CopyProfileControlsSource<Profile: ControlsProfileObject> {
    case nowhere
    case systemDefaults
    case otherProfile(ObjectBox<Profile>)
    
    struct Parts {
        var sourceType: SourceType
        var otherProfile: Profile?
        
        init(_ sourceType: SourceType, otherProfile: Profile? = nil) {
            self.sourceType = sourceType
            self.otherProfile = otherProfile
        }
    }
    
    enum SourceType {
        case nowhere
        case systemDefaults
        case otherProfile
    }
    
    init(from parts: Parts) {
        switch parts.sourceType {
        case .nowhere:
            self = .nowhere
        case .systemDefaults:
            self = .systemDefaults
        case .otherProfile:
            self = if let profile = parts.otherProfile {
                .otherProfile(.init(profile))
            } else {
                .nowhere
            }
        }
    }
}

extension ObjectActor {
    private func setControlsDataFromSource<InputSource: InputSourceDescriptorProtocol>(
        _: InputSource.Type,
        _ profile: inout InputSource.Object,
        from source: CopyProfileControlsSource<InputSource.Object>,
        in context: NSManagedObjectContext,
        system: System
    ) async {
        switch source {
        case .nowhere:
            profile.version = InputSource.Object.Version.latest
            profile.data = nil
        case .systemDefaults:
            let data = InputSource.defaults(for: system)
            profile.version = InputSource.Object.Version.latest
            profile.data = try? await ControlBindingsManager.encoder.encode(data)
        case .otherProfile(let box):
            guard let other = box.tryGet(in: context) else { return }
            profile.version = other.version
            profile.data = other.data
        }
    }

    func createProfile<InputSource: InputSourceDescriptorProtocol>(
        _ type: InputSource.Type,
        name: String,
        system: System,
        copying source: CopyProfileControlsSource<InputSource.Object>
    ) async throws -> ObjectBox<InputSource.Object> {
        var profile: InputSource.Object = self.objectContext.create()
        profile.name = name
        profile.system = system
        
        await self.setControlsDataFromSource(
            type,
            &profile,
            from: source,
            in: objectContext,
            system: system
        )

        try objectContext.saveIfNeeded()
        
        return .init(profile)
    }
}

extension ObjectActor {
    private func getAssignment(controllerID: String, system: System, game: ObjectBox<GameObject>?) throws -> ControllerProfileAssignmentObject? {
        let fetchRequest = ControllerProfileAssignmentObject.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = if let game {
            NSPredicate(format: "controllerID = %@ AND rawSystem = %d AND game.id = %@", controllerID, system.rawValue, game.id)
        } else {
            NSPredicate(format: "controllerID = %@ AND rawSystem = %d", controllerID, system.rawValue)
        }
        
        return try self.objectContext.fetch(fetchRequest).first
    }
    
    func getProfileForController(
        controllerID: String,
        system: System,
        game: ObjectBox<GameObject>?
    ) throws -> ObjectBox<ControllerProfileObject>? {
        return try getAssignment(controllerID: controllerID, system: system, game: game)?.profile.map(ObjectBox.init)
    }
    
    func setProfileForController(
        controllerID: String,
        system: System,
        game: ObjectBox<GameObject>?,
        to profileBox: ObjectBox<ControllerProfileObject>?
    ) throws {
        let assignment = try getAssignment(controllerID: controllerID, system: system, game: game)
        
        if let assignment, profileBox == nil {
            objectContext.delete(assignment)
            try objectContext.saveIfNeeded()
            return
        }
        
        guard let profileBox else { return }
        let profile = try profileBox.get(in: objectContext)
        
        if let assignment {
            assignment.profile = profile
            try objectContext.saveIfNeeded()
            return
        }
        
        ControllerProfileAssignmentObject.create(
            in: objectContext,
            controllerID: controllerID,
            system: system,
            game: game?.tryGet(in: objectContext),
            profile: profile
        )
        
        try objectContext.saveIfNeeded()
    }
}
