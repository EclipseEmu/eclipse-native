import Foundation
import EclipseKit

enum FileSystemPath {
    case rom(fileName: String, fileExtension: String?)
    case save(fileName: UUID, fileExtension: String?)
    case saveState(fileName: UUID, fileExtension: String?)
    case image(fileName: UUID, fileExtension: String?)
    case coreFile(coreID: String, fileID: UInt, fileExtension: String?)
    case other(URL)

    @usableFromInline
    var fileName: String {
        switch self {
        case .rom(let hash, _): hash
        case .save(let id, _), .saveState(let id, _), .image(let id, _): id.uuidString
        case .coreFile(_, let id, _): "\(id)"
        case .other(let url): url.fileName()
        }
    }

    @usableFromInline
    var fileExtension: String? {
        switch self {
        case .image(_, let ext), .rom(_, let ext), .save(_, let ext), .saveState(_, let ext), .coreFile(_, _, let ext): ext
        case .other(let url): url.fileExtension()
        }
    }
}

