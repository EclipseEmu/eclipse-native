import Foundation

fileprivate func createDirectoryIfNecessary(path: String, base: URL, with fileManager: FileManager) -> URL {
    let directory = base.appendingPathComponent(path, isDirectory: true)
    if !fileManager.fileExists(atPath: directory.path) {
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
    }
    return directory
}

struct ExternalStorage {
    enum Failure: LocalizedError {
        case missingRomPath
        case missingSavePath
        case failedToCreateFile
    }
    
    let fileManager: FileManager
    let romDirectory: URL
    let saveDirectory: URL
    let saveStateDirectory: URL
    let imageDirectory: URL
    
    init(fileManager: FileManager = .default) {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileManager = fileManager
        self.romDirectory = createDirectoryIfNecessary(path: "roms", base: documentDirectory, with: fileManager)
        self.saveDirectory = createDirectoryIfNecessary(path: "saves", base: documentDirectory, with: fileManager)
        self.saveStateDirectory = createDirectoryIfNecessary(path: "save_states", base: documentDirectory, with: fileManager)
        self.imageDirectory = createDirectoryIfNecessary(path: "images", base: documentDirectory, with: fileManager)
    }
    
    // MARK: Common
    
    @inlinable
    func getPath(name: String, fileExtension: String?, base: URL) -> URL {
        var filePath = name
        if let fileExtension {
            filePath += "." + fileExtension
        }
        return base.appendingPathComponent(filePath)
    }
    
    @inlinable
    func writeFile(path: URL, contents: Data) throws {
        guard fileManager.createFile(atPath: path.path, contents: contents, attributes: nil) else {
            throw Failure.failedToCreateFile
        }
    }
    
    @inlinable
    func deleteFile(path: URL) throws {
        guard self.fileManager.fileExists(atPath: path.path) else { return }
        try fileManager.removeItem(at: path)
    }

    // MARK: ROMs
    
    @inlinable
    func getRomPath(for game: Game) -> URL {
        return getPath(name: game.md5, fileExtension: game.romExtension, base: self.romDirectory)
    }
    
    @inlinable
    func writeRom(for game: Game, data: Data) throws {
        let path = getRomPath(for: game)
        try self.writeFile(path: path, contents: data)
    }
    
    @inlinable
    func deleteRom(for game: Game) throws {
        let path = getRomPath(for: game)
        try self.deleteFile(path: path)
    }

    // MARK: Saves
    
    @inlinable
    func getSavePath(for game: Game) -> URL {
        return getPath(name: game.id.uuidString, fileExtension: game.saveExtension, base: self.saveDirectory)
    }
    
    @inlinable
    func writeSave(for game: Game, data: Data) throws {
        let path = getSavePath(for: game)
        try self.writeFile(path: path, contents: data)
    }
    
    @inlinable
    func deleteSave(for game: Game) throws {
        let path = getSavePath(for: game)
        try self.deleteFile(path: path)
    }
    
    // MARK: Save States
    
    @inlinable
    func getSaveStatePath(for saveState: SaveState) -> URL {
        return getPath(name: saveState.id!.uuidString, fileExtension: saveState.fileExtension, base: self.saveStateDirectory)
    }
    
    @inlinable
    func writeSaveState(for saveState: SaveState, data: Data) throws {
        let path = getSaveStatePath(for: saveState)
        try self.writeFile(path: path, contents: data)
    }
    
    @inlinable
    func deleteSaveState(for saveState: SaveState) throws {
        let path = getSaveStatePath(for: saveState)
        try self.deleteFile(path: path)
    }
}
