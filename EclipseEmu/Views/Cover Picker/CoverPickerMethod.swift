import CoreData

enum CoverPickerMethod: Equatable, Identifiable {
    case database(GameObject)
    case photos(GameObject)

    var id: NSManagedObjectID {
        self.game.objectID
    }

    var game: GameObject {
        switch self {
        case .database(let game): game
        case .photos(let game): game
        }
    }
}
