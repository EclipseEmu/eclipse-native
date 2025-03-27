import CoreData

enum CoverPickerMethod: Equatable, Identifiable {
    case database(Game)
    case photos(Game)

    var id: NSManagedObjectID {
        self.game.objectID
    }

    var game: Game {
        switch self {
        case .database(let game): game
        case .photos(let game): game
        }
    }
}
