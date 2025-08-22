import Foundation

enum GameViewError: LocalizedError {
    case saveFileDoesNotExist
    case playbackError(GamePlaybackError)

    case saveFileImport(any Error)
    case saveFileExport(any Error)
    case saveFileDelete(FileSystemError)
    case replaceROM(any Error)

    case unknown(any Error)

    var errorDescription: String? {
        return switch self {
        case .playbackError(let error): error.errorDescription ?? error.localizedDescription
        case .saveFileDoesNotExist: "The save file does not exist."
        case .saveFileDelete(let error):
            "An error occurred while deleting the save: \(error.errorDescription ?? error.localizedDescription)"
        case .saveFileImport(let error):
            "An error occurred while importing the save: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        case .saveFileExport(let error):
            "An error occurred while exporting the save: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        case .replaceROM(let error):
            "An error occurred while replacing the ROM: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        case .unknown(let error):
            "An unknown error occurred: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)"
        }
    }
}
