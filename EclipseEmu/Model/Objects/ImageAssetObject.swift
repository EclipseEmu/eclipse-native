import CoreData
import Foundation
import OSLog

extension ImageAssetObject {
    var path: FileSystemPath {
        .image(fileName: id!, fileExtension: fileExtension)
    }

    @discardableResult
    static func create(in context: NSManagedObjectContext, id: UUID = UUID(), fileExtension: String?) -> Self {
        let model: Self = context.create()
        model.id = id
        model.fileExtension = fileExtension
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
                Logger.coredata.warning("image deletion failed: \(error.localizedDescription)")
            }
        }
    }
}
