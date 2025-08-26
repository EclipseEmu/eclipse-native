import Foundation

enum GameViewError: LocalizedError {
    case saveFileDoesNotExist
    case playbackError(GamePlaybackError)

    case saveFileImport(any Error)
    case saveFileExport(any Error)
    case saveFileDelete(FileSystemError)
    case replaceROM(any Error)
    case replaceSaveState(any Error)

    case unknown(any Error)

    var errorDescription: String? {
        return switch self {
        case .saveFileDoesNotExist: "The save file does not exist."
        case .playbackError(let error): error.errorDescription ?? error.localizedDescription
        case .saveFileDelete(let error):
            "An error occurred while deleting the save: \(error.errorDescription ?? error.localizedDescription)"
        case .saveFileImport(let error):
            "An error occurred while importing the save: \(errorString(error))"
        case .saveFileExport(let error):
            "An error occurred while exporting the save: \(errorString(error))"
        case .replaceROM(let error):
            "An error occurred while replacing the ROM: \(errorString(error))"
        case .replaceSaveState(let error):
            "An error occurred while replacing the save state: \(errorString(error))"
        case .unknown(let error):
            "An unknown error occurred: \(errorString(error))"
        }
    }
    
    private func errorString(_ error: any Error) -> String {
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
