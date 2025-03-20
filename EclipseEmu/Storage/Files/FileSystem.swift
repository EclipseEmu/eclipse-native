import Foundation
import CryptoKit
import OSLog
import CoreImage

private func createDirectory(path: String, base: URL, with fileManager: FileManager) -> URL {
    let directory = base.appendingPathComponent(path, isDirectory: true)
    if !fileManager.fileExists(atPath: directory.path) {
        Logger.fs.info("creating directory \"\(path)\"")
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    return directory
}

/// A dedicated thread/executor for File System I/O.
final actor FileSystem: Sendable {
    static let shared = FileSystem()

    private let fileManager: FileManager
    private let executor: BlockingSerialExecutor
    nonisolated let unownedExecutor: UnownedSerialExecutor

    let saveDirectory: URL
    let saveStateDirectory: URL
    let imageDirectory: URL
    let romDirectory: URL
    let coreDirectory: URL

    enum Path {
        case rom(fileName: String, fileExtension: String?)
        case save(fileName: UUID, fileExtension: String?)
        case saveState(fileName: UUID, fileExtension: String?)
        case image(fileName: UUID, fileExtension: String?)
        case other(URL)

        @usableFromInline
        var fileName: String {
            switch self {
            case .rom(let hash, _): hash
            case .save(let id, _), .saveState(let id, _), .image(let id, _): id.uuidString
            case .other(let url): url.fileName()
            }
        }

        @usableFromInline
        var fileExtension: String? {
            switch self {
            case .image(_, let ext), .rom(_, let ext), .save(_, let ext), .saveState(_, let ext): ext
            case .other(let url): url.fileExtension()
            }
        }

        @inlinable
        func base(in files: FileSystem) -> URL {
            switch self {
            case .image: files.imageDirectory
            case .rom: files.romDirectory
            case .save: files.saveDirectory
            case .saveState: files.saveStateDirectory
            case .other(let url): url.baseURL ?? url
            }
        }
    }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let queue = DispatchQueue(label: "dev.magnetar.eclipse.queue.fs")
        self.executor = BlockingSerialExecutor(queue: queue)
        self.unownedExecutor = executor.asUnownedSerialExecutor()

        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveDirectory = createDirectory(path: "saves", base: documentDirectory, with: fileManager)
        saveStateDirectory = createDirectory(path: "save_states", base: documentDirectory, with: fileManager)
        imageDirectory = createDirectory(path: "images", base: documentDirectory, with: fileManager)
        romDirectory = createDirectory(path: "roms", base: documentDirectory, with: fileManager)
        coreDirectory = createDirectory(path: "core", base: documentDirectory, with: fileManager)
    }

    func download(from url: URL, to destination: FileSystem.Path) async throws {
        Logger.fs.info("downloading \(url)")
        let (temporaryURL, _) = try await URLSession.shared.download(for: .init(url: url))
        try move(from: .other(temporaryURL), to: destination)
    }

    func download(from url: URL, overwriting destination: FileSystem.Path) async throws {
        Logger.fs.info("downloading \(url)")
        let (temporaryURL, _) = try await URLSession.shared.download(for: .init(url: url))
        try overwrite(moving: .other(temporaryURL), to: destination)
    }

    func delete(at path: FileSystem.Path) throws(FileSystemError) {
        let url = self.url(for: path)
        do {
            Logger.fs.info("deleting \(url)")
            try self.fileManager.removeItem(at: url)
        } catch let error as CocoaError {
            Logger.fs.error("failed to delete \(url): \(error.localizedDescription)")
            throw FileSystemError(from: error.code)
        } catch {
            Logger.fs.error("failed to delete \(url): \(error.localizedDescription)")
            throw .other(error)
        }
    }

    func copy(from sourcePath: FileSystem.Path, to destinationPath: FileSystem.Path) throws(FileSystemError) {
        let sourceUrl = url(for: sourcePath)
        let destinationUrl = url(for: destinationPath)
        do {
            Logger.fs.info("copying \(sourceUrl) to \(destinationUrl)")
            try self.fileManager.copyItem(at: sourceUrl, to: destinationUrl)
        } catch let error as CocoaError {
            Logger.fs.error("failed to copy \(sourceUrl) to \(destinationUrl): \(error.localizedDescription)")
            throw FileSystemError(from: error.code)
        } catch {
            Logger.fs.error("failed to copy \(sourceUrl) to \(destinationUrl): \(error.localizedDescription)")
            throw .other(error)
        }
    }

    func overwrite(copying sourcePath: FileSystem.Path, to destinationPath: FileSystem.Path) throws(FileSystemError) {
        try? self.delete(at: destinationPath)
        try self.copy(from: sourcePath, to: destinationPath)
    }

    func overwrite(moving sourcePath: FileSystem.Path, to destinationPath: FileSystem.Path) throws(FileSystemError) {
        try? self.delete(at: destinationPath)
        try self.copy(from: sourcePath, to: destinationPath)
    }

    func move(from sourcePath: FileSystem.Path, to destinationPath: FileSystem.Path) throws(FileSystemError) {
        let sourceUrl = url(for: sourcePath)
        let destinationUrl = url(for: destinationPath)
        do {
            Logger.fs.info("moving \(sourceUrl) to \(destinationUrl)")
            try self.fileManager.moveItem(at: sourceUrl, to: destinationUrl)
        } catch let error as CocoaError {
            Logger.fs.error("failed to move \(sourceUrl) to \(destinationUrl): \(error.localizedDescription)")
            throw FileSystemError(from: error.code)
        } catch {
            Logger.fs.error("failed to move \(sourceUrl) to \(destinationUrl): \(error.localizedDescription)")
            throw .other(error)
        }
    }

    func create(at path: FileSystem.Path, with contents: Data) -> Bool {
        let url = self.url(for: path)
        Logger.fs.info("creating file at \(url)")
        return self.fileManager.createFile(atPath: url.path(percentEncoded: false), contents: contents)
    }

    func md5(for file: URL) async throws(FileSystemError) -> String {
        let stream = try FileStream(at: file)
        await Task.yield()
        var hasher = Insecure.MD5()
        var buf = [UInt8](repeating: 0, count: 1024)
        while case let amount = try stream.read(into: &buf), amount > 0 {
            hasher.update(data: buf[..<amount])
            await Task.yield()
        }
        return hasher.finalize().hexString()
    }

    func exists(path: FileSystem.Path) -> Bool {
        self.fileManager.fileExists(atPath: self.url(for: path).path(percentEncoded: false))
    }

    func writeJPEG(of image: CIImage, to path: FileSystem.Path) throws {
        let context = CIContext()
        try context.writeJPEGRepresentation(
            of: image,
            to: self.url(for: path),
            colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        )
    }

    nonisolated func url(for path: FileSystem.Path) -> URL {
        if case .other(let url) = path {
            return url
        }

        var (fileName, fileExtension, base) = switch path {
        case .rom(let hash, let ext): (hash, ext, romDirectory)
        case .save(let id, let ext): (id.uuidString, ext, saveDirectory)
        case .saveState(let id, let ext): (id.uuidString, ext, saveStateDirectory)
        case .image(let id, let ext): (id.uuidString, ext, imageDirectory)
        case .other(_): unreachable("FileSystem.Path.other() is already handled")
        }

        if let fileExtension, !fileExtension.isEmpty {
            fileName.append(".")
            fileName.append(fileExtension)
        }

        return base.appending(component: fileName, directoryHint: .notDirectory)
    }

    nonisolated func url(path: FileSystem.Path?) -> URL? {
        guard let path else { return nil }
        return self.url(for: path)
    }
}
