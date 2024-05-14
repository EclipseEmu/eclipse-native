import Foundation

struct FileStream: ~Copyable {
    enum Failure: Error {
        case failedToOpen
        case failedToRead
    }
    
    enum Mode {
        case readOnly
        
        var rawValue: Int32 {
            switch self {
            case .readOnly: O_RDONLY
            }
        }
    }
    
    private let fd: Int32
    private var closed: Bool = false
    
    private let queue: DispatchQueue
    private let io: DispatchIO
    
    init(url: URL, mode: Mode, permissions: mode_t = 0o666) throws {
        guard url.isFileURL else { throw Failure.failedToOpen }
        
        let fd = Darwin.open(url.absoluteURL.path, mode.rawValue, permissions)
        guard fd != -1 else { throw Failure.failedToOpen }
        
        self.queue = DispatchQueue(label: "dev.magnetar.eclipse.FileStream")
        self.fd = fd
        self.io = DispatchIO(
            type: .stream,
            fileDescriptor: fd,
            queue: queue,
            cleanupHandler: { [fd] error in
                if error != 0 {
                    print("creating or opening the file stream failed:", error)
                }
                Darwin.close(fd)
            }
        )
    }
    
    deinit {
        guard !closed else { return }
        Darwin.close(fd)
    }
    
    consuming func close() {
        self.closed = true
        self.io.close()
    }
    
    func read(amount: Int) async throws -> DispatchData {
        try await withCheckedThrowingContinuation { continuation in
            var accumulator = DispatchData.empty
            self.io.read(offset: 0, length: amount, queue: self.queue, ioHandler: { done, data, error in
                if let data {
                    accumulator.append(data)
                }
                
                guard done else { return }
                
                guard error == 0 else {
                    continuation.resume(throwing: Failure.failedToRead)
                    return
                }
                
                continuation.resume(returning: accumulator)
            })
        }
    }
    
    @inlinable
    func readAll() async throws -> DispatchData {
        try await self.read(amount: .max)
    }
}
