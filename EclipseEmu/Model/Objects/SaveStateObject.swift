import CoreData
import Foundation
import OSLog

extension SaveStateObject {
    var path: FileSystemPath {
        .saveState(fileName: id!, fileExtension: fileExtension)
    }

	var core: Core? {
		get {
			Core(rawValue: self.rawCore)
		}
		set {
			rawCore = newValue?.rawValue ?? -1
		}
	}

    @discardableResult
    static func create(
        in context: NSManagedObjectContext,
        id: UUID = UUID(),
        isAuto: Bool,
        core: Core,
        stateExtension: String? = "s8",
        preview: ImageAssetObject? = nil,
        game: GameObject? = nil
    ) -> Self {
        let model: Self = context.create()
        model.id = id
        model.isAuto = isAuto
        model.date = Date()
        model.preview = preview
        model.core = core
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
