import CoreData
import Foundation
import OSLog

extension SaveState {
    @discardableResult
    convenience init(
        insertInto context: NSManagedObjectContext,
        id: UUID = UUID(),
        isAuto: Bool,
        stateExtension: String?,
        preview: ImageAsset? = nil,
        game: Game? = nil
    ) {
        self.init(context: context)
        self.id = id
        self.isAuto = isAuto
        self.date = Date()
        self.preview = preview
        self.fileExtension = stateExtension
        self.game = game
    }

    var path: FileSystemPath {
        .saveState(fileName: id!, fileExtension: fileExtension)
    }

    override public func didSave() {
        super.didSave()
        guard self.isDeleted else { return }

        let path = path
        Task {
            do {
                try await FileSystem.shared.delete(at: path)
            } catch {
                Logger.coredata.warning("save state deletion failed: \(error.localizedDescription)")
            }
        }
    }
}
