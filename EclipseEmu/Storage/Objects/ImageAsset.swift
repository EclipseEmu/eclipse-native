import CoreData
import Foundation
import OSLog

extension ImageAsset {
    convenience init(id: UUID = UUID(), fileExtension: String?) {
        self.init(entity: Self.entity(), insertInto: nil)
        self.id = id
        self.fileExtension = fileExtension
    }

    var path: FileSystemPath {
        .image(fileName: id!, fileExtension: fileExtension)
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
