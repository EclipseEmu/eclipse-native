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

    case network(any Error)

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

    var errorDescription: String? {
        switch self {
        case .other(let error): error.localizedDescription
        case .network(let error): error.localizedDescription
        case .unknown: "an unknown error occurred"
        case .fileNoSuchFile: "file does not exist"
        case .fileLocking: "the file is locked"
        case .fileReadUnknown: "an unknown error occurred while trying to read the file"
        case .fileReadNoPermission: "missing permissions to read the file"
        case .fileReadInvalidFileName: "unable to read file because of an invalid file name"
        case .fileReadCorruptFile: "unable to read the file because it is corrupted"
        case .fileReadNoSuchFile: "unable to read the file because it does not exist"
        case .fileReadInapplicableStringEncoding: "unable to read the file because it is encoded in an inapplicable format"
        case .fileReadUnsupportedScheme: "unable to read the file because of an unsupported scheme"
        case .fileReadTooLarge: "unable to read the file because it is too large"
        case .fileReadUnknownStringEncoding: "unable to read the file because it uses an unknown string encoding"
        case .fileWriteUnknown: "an unknown error occurred while trying to write the file"
        case .fileWriteNoPermission: "missing permissions to write to the file"
        case .fileWriteInvalidFileName: "unable to write to the file because of an invalid file name"
        case .fileWriteFileExists: "file does not exist"
        case .fileWriteInapplicableStringEncoding: "unable to write to the file because it is encoded in an inapplicable format"
        case .fileWriteUnsupportedScheme: "unable to write to the file because of an unsupported scheme"
        case .fileWriteOutOfSpace: "unable to write to the file because the device is out of space"
        case .fileWriteVolumeReadOnly: "unable to write to the file because the volume is read only"
        }
    }
}
