import Foundation

enum GameObjectError: LocalizedError {
    case failedToAccessSecurityScopedResource
    case failedToGetReadPermissions
    case unknownFileType
    case persistence(PersistenceError)
    case files(FileSystemError)

    var errorDescription: String? {
        switch self {
        case .failedToAccessSecurityScopedResource: "unable to access the file due to security restrictions"
        case .failedToGetReadPermissions: "unable to read the file"
        case .unknownFileType: "the uploaded file type is unsupported"
        case .persistence(let error): error.localizedDescription
        case .files(let error): error.localizedDescription
        }
    }
}

enum SaveStateObjectError: Error {
    case failedToCreateSaveState
    case persistence(PersistenceError)
    case files(FileSystemError)

    var errorDescription: String? {
        switch self {
        case .failedToCreateSaveState: "failed to create the save state"
        case .persistence(let error): error.localizedDescription
        case .files(let error): error.localizedDescription
        }
    }
}

enum ImageAssetObjectError: Error {
    case network(any Error)
    case persistence(PersistenceError)
    case files(FileSystemError)

    var errorDescription: String? {
        switch self {
        case .network(let error): error.localizedDescription
        case .persistence(let error): error.localizedDescription
        case .files(let error): error.localizedDescription
        }
    }
}
