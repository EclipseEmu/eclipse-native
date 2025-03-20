import Foundation

enum FileSystemError: LocalizedError {
    case other(any Error)
    case unknown

    case fileNoSuchFile
    case fileLocking
    case fileReadUnknown
    case fileReadNoPermission
    case fileReadInvalidFileName
    case fileReadCorruptFile
    case fileReadNoSuchFile
    case fileReadInapplicableStringEncoding
    case fileReadUnsupportedScheme
    case fileReadTooLarge
    case fileReadUnknownStringEncoding
    case fileWriteUnknown
    case fileWriteNoPermission
    case fileWriteInvalidFileName
    case fileWriteFileExists
    case fileWriteInapplicableStringEncoding
    case fileWriteUnsupportedScheme
    case fileWriteOutOfSpace
    case fileWriteVolumeReadOnly

    init(from cocoaError: CocoaError.Code) {
        self = switch cocoaError {
        case .fileNoSuchFile: .fileNoSuchFile
        case .fileLocking: .fileLocking
        case .fileReadUnknown: .unknown
        case .fileReadNoPermission: .fileReadNoPermission
        case .fileReadInvalidFileName: .fileReadInvalidFileName
        case .fileReadCorruptFile: .fileReadCorruptFile
        case .fileReadNoSuchFile: .fileReadNoSuchFile
        case .fileReadInapplicableStringEncoding: .fileReadInapplicableStringEncoding
        case .fileReadUnsupportedScheme: .fileReadUnsupportedScheme
        case .fileReadTooLarge: .fileReadTooLarge
        case .fileReadUnknownStringEncoding: .fileReadUnknownStringEncoding
        case .fileWriteUnknown: .unknown
        case .fileWriteNoPermission: .fileWriteNoPermission
        case .fileWriteInvalidFileName: .fileWriteInvalidFileName
        case .fileWriteFileExists: .fileWriteFileExists
        case .fileWriteInapplicableStringEncoding: .fileWriteInapplicableStringEncoding
        case .fileWriteUnsupportedScheme: .fileWriteUnsupportedScheme
        case .fileWriteOutOfSpace: .fileWriteOutOfSpace
        case .fileWriteVolumeReadOnly: .fileWriteVolumeReadOnly
        default: .unknown
        }
    }
}
