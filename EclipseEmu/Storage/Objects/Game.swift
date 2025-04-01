import CoreData
import Foundation
import EclipseKit
import OSLog

extension Game {
    var romPath: FileSystemPath {
        .rom(fileName: sha1!, fileExtension: romExtension)
    }

    var savePath: FileSystemPath {
        .save(fileName: id!, fileExtension: saveExtension)
    }

    var system: GameSystem {
        get {
            GameSystem(rawValue: UInt32(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int32(newValue.rawValue)
        }
    }

    convenience init(
        uuid: UUID = UUID(),
        name: String,
        system: GameSystem,
        sha1: String,
        romExtension: String?,
        saveExtension: String?,
        cover: ImageAsset?
    ) {
        self.init(entity: Self.entity(), insertInto: nil)

        self.id = uuid
        self.name = name
        self.system = system
        self.dateAdded = Date()
        self.sha1 = sha1
        self.romExtension = romExtension
        self.saveExtension = saveExtension
        self.cover = cover
    }

    override public func didSave() {
        super.didSave()

        guard isDeleted, let sha1 else { return }
        let romPath = self.romPath
        let savePath = self.savePath

        Task {
            do {
                try await FileSystem.shared.delete(at: savePath)
            } catch {
                Logger.coredata.warning("failed to delete save: \(error.localizedDescription)")
            }
        }

        Task {
            guard await Persistence.shared.objects.canDeleteRom(sha1: sha1) else { return }
            do {
                try await FileSystem.shared.delete(at: romPath)
            } catch {
                Logger.coredata.warning("failed to delete rom: \(error.localizedDescription)")
            }
        }
    }
}
