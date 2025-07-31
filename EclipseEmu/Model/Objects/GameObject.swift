import CoreData
import Foundation
import EclipseKit
import OSLog

extension GameObject {
    var romPath: FileSystemPath {
        .rom(fileName: sha1!, fileExtension: romExtension)
    }

    var savePath: FileSystemPath {
        .save(fileName: id!, fileExtension: saveExtension)
    }

    var system: System {
        get {
            System(rawValue: UInt16(self.rawSystem)) ?? .unknown
        }
        set {
            self.rawSystem = Int16(newValue.rawValue)
        }
    }

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        uuid: UUID = UUID(),
        name: String,
        system: System,
        sha1: String,
        romExtension: String?,
        saveExtension: String?,
        cover: ImageAssetObject? = nil
    ) -> Self {
        let model: Self = context.create()
        model.id = uuid
        model.name = name
        model.system = system
        model.dateAdded = Date()
        model.sha1 = sha1
        model.romExtension = romExtension
        model.saveExtension = saveExtension
        model.cover = cover
        return model
    }

    override public func didSave() {
        super.didSave()

        guard isDeleted, let sha1 else { return }
        let romPath = self.romPath
        let savePath = self.savePath

        Task {
            do {
                try await FileSystem.shared.delete(at: savePath)
            } catch FileSystemError.fileNoSuchFile {} catch {
                Logger.coredata.warning("failed to delete save: \(error.localizedDescription)")
            }
        }

        Task {
            guard await Persistence.shared.objects.canDeleteRom(sha1: sha1) else { return }
            do {
                try await FileSystem.shared.delete(at: romPath)
            } catch FileSystemError.fileNoSuchFile {} catch {
                Logger.coredata.warning("failed to delete rom: \(error.localizedDescription)")
            }
        }
    }
}
