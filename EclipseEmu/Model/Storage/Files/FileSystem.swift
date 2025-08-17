import Foundation
import CryptoKit
import OSLog
import CoreImage

@discardableResult
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
    private let executor: DispatchQueueSerialExecutor
    nonisolated let unownedExecutor: UnownedSerialExecutor

    let saveDirectory: URL
    let saveStateDirectory: URL
    let imageDirectory: URL
    let romDirectory: URL
    let coreDirectory: URL

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let queue = DispatchQueue(label: "dev.magnetar.eclipse.queue.fs")
        self.executor = DispatchQueueSerialExecutor(queue: queue)
        self.unownedExecutor = executor.asUnownedSerialExecutor()

        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        saveDirectory = createDirectory(path: "saves", base: documentDirectory, with: fileManager)
        saveStateDirectory = createDirectory(path: "save_states", base: documentDirectory, with: fileManager)
        imageDirectory = createDirectory(path: "images", base: documentDirectory, with: fileManager)
        romDirectory = createDirectory(path: "roms", base: documentDirectory, with: fileManager)
        coreDirectory = createDirectory(path: "core", base: documentDirectory, with: fileManager)
        for core in Core.allCases {
            createDirectory(path: core.type.id, base: coreDirectory, with: fileManager)
        }
    }

    func download(from url: URL, to destination: FileSystemPath) async throws(FileSystemError) {
        Logger.fs.info("downloading \(url)")
        let temporaryURL: URL
        do {
            (temporaryURL, _) = try await URLSession.shared.download(for: .init(url: url))
        } catch {
            throw .network(error)
        }
        try move(from: .other(temporaryURL), to: destination)
    }

    func download(from url: URL, overwriting destination: FileSystemPath) async throws(FileSystemError) {
        Logger.fs.info("downloading \(url)")
        let temporaryURL: URL
        do {
            (temporaryURL, _) = try await URLSession.shared.download(for: .init(url: url))
        } catch {
            throw .network(error)
        }
        try overwrite(moving: .other(temporaryURL), to: destination)
    }

    func delete(at path: FileSystemPath) throws(FileSystemError) {
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

    func copy(from sourcePath: FileSystemPath, to destinationPath: FileSystemPath) throws(FileSystemError) {
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

    func overwrite(copying sourcePath: FileSystemPath, to destinationPath: FileSystemPath) throws(FileSystemError) {
        try? self.delete(at: destinationPath)
        try self.copy(from: sourcePath, to: destinationPath)
    }

    func overwrite(moving sourcePath: FileSystemPath, to destinationPath: FileSystemPath) throws(FileSystemError) {
        try? self.delete(at: destinationPath)
        try self.copy(from: sourcePath, to: destinationPath)
    }

    func move(from sourcePath: FileSystemPath, to destinationPath: FileSystemPath) throws(FileSystemError) {
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

    func create(at path: FileSystemPath, with contents: Data) -> Bool {
        let url = self.url(for: path)
        Logger.fs.info("creating file at \(url)")
        return self.fileManager.createFile(atPath: url.path(percentEncoded: false), contents: contents)
    }

    func sha1(for file: URL) async throws(FileSystemError) -> String {
        let stream = try FileStream(at: file)
        await Task.yield()
        var hasher = Insecure.SHA1()
        var buf = [UInt8](repeating: 0, count: 1024)
        while case let amount = try stream.read(into: &buf), amount > 0 {
            hasher.update(data: buf[..<amount])
            await Task.yield()
        }
        return hasher.finalize().hexString()
    }

    func exists(path: FileSystemPath) -> Bool {
        self.fileManager.fileExists(atPath: self.url(for: path).path(percentEncoded: false))
    }

    func writeJPEG(of image: CIImage, to path: FileSystemPath) throws(FileSystemError) {
        let context = CIContext()
        do {
            try context.writeJPEGRepresentation(
                of: image,
                to: self.url(for: path),
                colorSpace: image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            )
        } catch {
            throw .other(error)
        }
    }

    nonisolated func url(for path: FileSystemPath) -> URL {
        if case .other(let url) = path {
            return url
        }

        var (fileName, fileExtension, base) = switch path {
        case .rom(let hash, let ext): (hash, ext, romDirectory)
        case .save(let id, let ext): (id.uuidString, ext, saveDirectory)
        case .saveState(let id, let ext): (id.uuidString, ext, saveStateDirectory)
        case .image(let id, let ext): (id.uuidString, ext, imageDirectory)
        case .coreFile(coreID: let id, fileID: let fileID, fileExtension: let ext): ("\(fileID)", ext, coreDirectory.appending(path: id, directoryHint: .isDirectory))
        case .other(_): unreachable("FileSystem.Path.other() is already handled")
        }

        if let fileExtension, !fileExtension.isEmpty {
            if fileExtension.first != "." {
                fileName.append(".")
            }
            fileName.append(fileExtension)
        }

        return base.appending(component: fileName, directoryHint: .notDirectory)
    }

    nonisolated func url(path: FileSystemPath?) -> URL? {
        guard let path else { return nil }
        return self.url(for: path)
    }
}
