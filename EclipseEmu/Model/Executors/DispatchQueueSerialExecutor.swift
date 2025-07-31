import Foundation

/// Pushes task execution onto a DispatchQueue, moving blocking operations out of the Swift Concurrency thread pool.
final class DispatchQueueSerialExecutor: @unchecked Sendable, SerialExecutor {
    let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func enqueue(_ job: UnownedJob) {
        self.queue.async {
            job.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}

