import Foundation

typealias MD5 = String

final class Files: Sendable {
    enum Failure: LocalizedError {
        case invalidPath
        case other(any Error)
    }

    enum Path {
        case rom(MD5, String?)
        case save(UUID, String?)
        case saveState(UUID)
        case image(UUID, String?)
        case other(URL)

        @usableFromInline
        var fileName: String {
            switch self {
            case .rom(let hash, _): hash
            case .save(let id, _), .saveState(let id), .image(let id, _): id.uuidString
            case .other(let url): url.fileName()
            }
        }

        @usableFromInline
        var fileExtension: String? {
            switch self {
            case .image(_, let ext), .rom(_, let ext), .save(_, let ext): ext
            case .saveState: nil
            case .other(let url): url.fileExtension()
            }
        }

        @inlinable
        func base(in files: Files) -> URL {
            switch self {
            case .image: files.imageDirectory
            case .rom: files.romDirectory
            case .save: files.saveDirectory
            case .saveState: files.saveStateDirectory
            case .other(let url): url.baseURL ?? url
            }
        }

        func path(in files: Files) -> URL? {
            if case .other(let url) = self {
                return url
            }

            var fileName = self.fileName
            if let fileExtension = self.fileExtension, !fileExtension.isEmpty {
                fileName.append(".")
                fileName.append(fileExtension)
            }
            return URL(string: fileName, relativeTo: self.base(in: files))
        }
    }

    static let shared: Files = .init(manager: .default)

    private nonisolated(unsafe) let manager: FileManager
    let imageDirectory: URL
    let romDirectory: URL
    let saveDirectory: URL
    let saveStateDirectory: URL

    private static func createDirectory(path: String, base: URL, with fileManager: FileManager) -> URL {
        let directory = base.appendingPathComponent(path, isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        return directory
    }

    init(manager: FileManager) {
        let documentDirectory = manager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.romDirectory = Self.createDirectory(path: "roms", base: documentDirectory, with: manager)
        self.saveDirectory = Self.createDirectory(path: "saves", base: documentDirectory, with: manager)
        self.saveStateDirectory = Self.createDirectory(path: "save_states", base: documentDirectory, with: manager)
        self.imageDirectory = Self.createDirectory(path: "images", base: documentDirectory, with: manager)
        self.manager = manager
    }

    @inlinable
    func path(to file: Path) -> URL? {
        file.path(in: self)
    }

    // MARK: Blocking APIs

    @inlinable
    func existsSync(file: Path) -> Bool {
        guard let path = file.path(in: self) else { return false }
        return self.manager.fileExists(atPath: path.path)
    }

    @inlinable
    func existsSync(url: URL) -> Bool {
        return self.manager.fileExists(atPath: url.path)
    }

    @inlinable
    func createSync(
        file: Path,
        contents: Data?,
        attributes: [FileAttributeKey: Any]? = nil
    ) -> Bool {
        guard let path = file.path(in: self) else { return false }
        return self.manager.createFile(atPath: path.path, contents: contents, attributes: attributes)
    }

    @inlinable
    func deleteSync(file: Path) throws(Files.Failure) {
        guard let url = file.path(in: self) else { throw .invalidPath }
        do {
            try self.manager.removeItem(at: url)
        } catch {
            throw .other(error)
        }
    }

    @inlinable
    func moveSync(from source: URL, to dest: Path) throws(Files.Failure) {
        guard let destUrl = dest.path(in: self) else { throw .invalidPath }
        do {
            try? self.manager.removeItem(at: destUrl)
            try self.manager.moveItem(at: source, to: destUrl)
        } catch {
            throw .other(error)
        }
    }

    @inlinable
    func copySync(from source: URL, to dest: Path) throws(Files.Failure) {
        guard let destUrl = dest.path(in: self) else { throw .invalidPath }
        do {
            try? self.manager.removeItem(at: destUrl)
            try self.manager.copyItem(at: source, to: destUrl)
        } catch {
            throw .other(error)
        }
    }

    // MARK: Asynchronous APIs

    @inlinable
    func exists(file: Path) async -> Bool {
        await Task.blocking {
            self.existsSync(file: file)
        }
    }

    @inlinable
    func exists(url: URL) async -> Bool {
        await Task.blocking {
            self.existsSync(url: url)
        }
    }

    @inlinable
    func create(file: Path, contents: Data?) async -> Bool {
        await Task.blocking {
            self.createSync(file: file, contents: contents)
        }
    }

    @inlinable
    func delete(file: Path) async throws(Files.Failure) {
        do {
            try await Task.blocking {
                try self.deleteSync(file: file)
            }
        } catch {
            throw error as! Files.Failure
        }
    }

    @inlinable
    func move(from source: URL, to dest: Path) async throws(Files.Failure) {
        do {
            try await Task.blocking {
                try self.moveSync(from: source, to: dest)
            }
        } catch {
            throw error as! Files.Failure
        }
    }

    @inlinable
    func copy(from source: URL, to dest: Path) async throws(Files.Failure) {
        do {
            try await Task.blocking {
                try self.copySync(from: source, to: dest)
            }
        } catch {
            throw error as! Files.Failure
        }
    }
    
    func download(from remote: URL, to dest: Path) async throws {
        let (url, _) = try await URLSession.shared.download(from: remote)
        try await self.move(from: url, to: dest)
    }

    func clean(files: [Path?]) async {
        await withTaskGroup(of: Void.self) { taskGroup in
            for path in files {
                guard let path else { return }
                taskGroup.addTask(priority: .background) {
                    try? await self.delete(file: path)
                }
            }
            await taskGroup.waitForAll()
        }
    }
}
