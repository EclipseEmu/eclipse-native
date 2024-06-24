import Foundation
import CoreData

extension Persistence {
    @inlinable
    func rename(saveState: Persistence.Object<SaveState>, to newName: String) async throws {
        try await self.update(saveState) { saveState, _ in
            saveState.name = newName
        }
    }

    func create(saveStateIn coreCoordinator: GameCoreCoordinator, for game: Persistence.Object<Game>, isAuto: Bool) async throws {
        let id = UUID()

        let previewId = UUID()
        let previewExtension = "jpeg"

        // FIXME: Handle cleanup in the event of failure.

        let (imageAssetData, _): (()?, ()) = await (
            try? coreCoordinator.writeScreenshot(to: Files.Path.image(previewId, previewExtension)),
            try Self.writeState(coreCoordinator: coreCoordinator, id: id)
        )

        try await self.perform { context in
            var saveState: SaveState
            let game = try game.unwrap(in: context)

            if isAuto, let item = Self.isOnlyAutoState(for: game, in: context) {
                saveState = item
                if let preview = saveState.preview {
                    context.delete(preview)
                }
            } else {
                saveState = SaveState(context: context)
            }

            saveState.id = id
            saveState.date = .now
            saveState.isAuto = isAuto
            saveState.game = game

            if imageAssetData != nil {
                let previewAsset = ImageAsset(context: context)
                previewAsset.id = previewId
                previewAsset.fileExtension = previewExtension
                saveState.preview = previewAsset
            }

            try context.save()
        }
    }

    private static func writeState(coreCoordinator: GameCoreCoordinator, id: UUID) async throws {
        guard
            let path = Files.Path.saveState(id).path(in: .shared),
            await coreCoordinator.saveState(to: path)
        else {
            throw PersistenceError.saveStateFailure(.failedCreation)
        }
    }

    private static func isOnlyAutoState(for game: Game, in context: NSManagedObjectContext) -> SaveState? {
        let request = SaveState.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "(isAuto == true) AND (game == %@)", game)
        return try? context.fetch(request).first
    }
}
