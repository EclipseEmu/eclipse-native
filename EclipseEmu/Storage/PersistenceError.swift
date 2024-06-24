import Foundation

enum PersistenceError: LocalizedError {
    case saveFailed(any Error)
    case unwrapFailed
    case gameFailure(GameFailure)
    case saveStateFailure(SaveStateFailure)

    enum GameFailure: LocalizedError {
        case failedPathCreation
        case invalidPermissions
        case unknownSystem
    }

    enum SaveStateFailure: LocalizedError {
        case failedCreation
    }
}
