import Foundation

/// Wraps a blocking operation in a DispatchQueue, such that the Swift Concurrency pool will not be oversaturated.
/// - Parameters:
///   - queue: The dispatch queue to offload work to. Defaults to the global queue, with no specified QoS.
///   - body: The code block to run
/// - Returns: The continuation's return value
@inlinable
func withCheckedBlockingContinuation<T>(
    queue: DispatchQueue = .global(),
    body: @escaping (CheckedContinuation<T, Never>) -> Void
) async -> T {
    return await withCheckedContinuation { continuation in
        queue.async {
            body(continuation)
        }
    }
}

/// Wraps a blocking operation in a DispatchQueue, such that the Swift Concurrency pool will not be oversaturated.
/// - Parameters:
///   - queue: The dispatch queue to offload work to. Defaults to the global queue, with no specified QoS.
///   - body: The code block to run
/// - Returns: The continuation's return value
/// - Throws: The continuation's thrown value
@inlinable
func withCheckedBlockingThrowingContinuation<T>(
    queue: DispatchQueue = .global(),
    body: @escaping (CheckedContinuation<T, any Error>) -> Void
) async throws -> T {
    return try await withCheckedThrowingContinuation { continuation in
        queue.async {
            body(continuation)
        }
    }
}

/// Wraps a blocking operation in a DispatchQueue, such that the Swift Concurrency pool will not be oversaturated.
/// - Parameters:
///   - queue: The dispatch queue to offload work to. Defaults to the global queue, with no specified QoS.
///   - body: The code block to run
/// - Returns: The continuation's return value
@inlinable
func withUnsafeBlockingContinuation<T>(
    queue: DispatchQueue = .global(),
    body: @escaping (UnsafeContinuation<T, Never>) -> Void
) async -> T {
    return await withUnsafeContinuation { continuation in
        queue.async {
            body(continuation)
        }
    }
}

/// Wraps a blocking operation in a DispatchQueue, such that the Swift Concurrency pool will not be oversaturated.
/// - Parameters:
///   - queue: The dispatch queue to offload work to. Defaults to the global queue, with no specified QoS.
///   - body: The code block to run
/// - Returns: The continuation's return value
/// - Throws: The continuation's thrown value
@inlinable
func withUnsafeBlockingThrowingContinuation<T>(
    queue: DispatchQueue = .global(),
    body: @escaping (UnsafeContinuation<T, any Error>) -> Void
) async throws -> T {
    return try await withUnsafeThrowingContinuation { continuation in
        queue.async {
            body(continuation)
        }
    }
}
