import CoreData
import Foundation
import OSLog

extension SaveState {
    var path: FileSystemPath {
        .saveState(fileName: id!, fileExtension: fileExtension)
    }

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        id: UUID = UUID(),
        isAuto: Bool,
        stateExtension: String? = "s8",
        preview: ImageAsset? = nil,
        game: Game? = nil
    ) -> Self {
        let model: Self = context.create()
        model.id = id
        model.isAuto = isAuto
        model.date = Date()
        model.preview = preview
        model.fileExtension = stateExtension
        model.game = game
        return model
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
