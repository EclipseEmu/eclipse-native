import Foundation

enum PersistenceError: LocalizedError {
    case save(any Error)
    case fetch(any Error)
    case obtain(any Error)

    var errorDescription: String? {
        switch self {
        case .save(let error): "failed to save the database's state: \(error.localizedDescription)"
        case .fetch(let error): "failed to execute fetch request: \(error.localizedDescription)"
        case .obtain(let error): "failed to obtain object: \(error.localizedDescription)"
        }
    }
}
