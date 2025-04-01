import Foundation

enum PersistenceError: LocalizedError {
    case typeMismatch
    case saveError(any Error)
    case fetchError(any Error)
    case coreDataError(any Error)

    var errorDescription: String? {
        switch self {
        case .typeMismatch: "the object's type did not match the expected type"
        case .saveError(let error): "failed to save the database's state: \(error.localizedDescription)"
        case .fetchError(let error): "failed to execute fetch request: \(error.localizedDescription)"
        case .coreDataError(let error): "an unknown error occurred: \(error.localizedDescription)"
        }
    }
}
