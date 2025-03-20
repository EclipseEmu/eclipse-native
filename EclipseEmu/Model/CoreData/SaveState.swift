import CoreData
import Foundation
import OSLog

extension SaveState {
    convenience init(
        id: UUID = UUID(),
        isAuto: Bool,
        stateExtension: String?,
        preview: ImageAsset?,
        game: Game?
    ) {
        self.init(entity: Self.entity(), insertInto: nil)

        self.id = id
        self.isAuto = isAuto
        self.date = Date()
        self.preview = preview
        self.fileExtension = stateExtension
        self.game = game
    }

    var path: FileSystem.Path {
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
