import Foundation
import System
import OSLog

struct FileStream: ~Copyable {
    let fd: FileDescriptor

    init(at path: URL) throws(FileSystemError) {
        do {
            let filePath: FilePath = .init(path.path(percentEncoded: false))
            Logger.fs.info("opening file \(filePath)")
            self.fd = try FileDescriptor.open(filePath, .readOnly)
        } catch let error as CocoaError {
            throw FileSystemError(from: error.code)
        } catch {
            throw .other(error)
        }
    }

    deinit {
        try? self.fd.close()
    }

    func read(into array: inout [UInt8]) throws(FileSystemError) -> Int {
        do {
            return try array.withUnsafeMutableBufferPointer { ptr in
                return try fd.read(into: UnsafeMutableRawBufferPointer(ptr))
            }
        } catch let error as CocoaError {
            throw FileSystemError(from: error.code)
        } catch {
            throw .other(error)
        }
    }
}
