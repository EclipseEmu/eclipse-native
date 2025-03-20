import Foundation

enum PersistenceError: LocalizedError {
    case typeMismatch
    case unresolvedID
    case coordinatorMissing
    case saveError(any Error)
    case coreDataError(any Error)
}
