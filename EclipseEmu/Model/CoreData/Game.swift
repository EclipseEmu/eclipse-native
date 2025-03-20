import CoreData
import Foundation
import EclipseKit
import OSLog

extension Game {
    var romPath: FileSystem.Path {
        .rom(fileName: md5!, fileExtension: romExtension)
    }

    var savePath: FileSystem.Path {
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
        md5: String,
        romExtension: String?,
        saveExtension: String?,
        boxart: ImageAsset?
    ) {
        self.init(entity: Self.entity(), insertInto: nil)

        self.id = uuid
        self.name = name
        self.system = system
        self.dateAdded = Date()
        self.md5 = md5
        self.romExtension = romExtension
        self.saveExtension = saveExtension
        self.boxart = boxart
    }

    override public func didSave() {
        super.didSave()

        guard isDeleted, let md5 else { return }
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
            guard await Persistence.shared.library.canDeleteRom(md5: md5) else { return }
            do {
                try await FileSystem.shared.delete(at: romPath)
            } catch {
                Logger.coredata.warning("failed to delete rom: \(error.localizedDescription)")
            }
        }
    }
}
