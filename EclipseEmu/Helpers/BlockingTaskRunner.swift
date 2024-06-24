import Foundation

extension Task where Success == Never, Failure == Never {
    @inlinable
    static func blocking<T>(on queue: DispatchQueue = .global(), body: @escaping @Sendable () -> T) async -> T {
        await withUnsafeContinuation { continuation in
            queue.async {
                continuation.resume(returning: body())
            }
        }
    }

    @inlinable
    static func blocking<T, E>(on queue: DispatchQueue = .global(), body: @escaping @Sendable () throws(E) -> T) async throws(E) -> T {
        let result: Result<T, E> = await withUnsafeContinuation { continuation in
            queue.async {
                do {
                    let response = try body()
                    continuation.resume(returning: .success(response))
                } catch {
                    continuation.resume(returning: .failure(error as! E))
                }
            }
        }
        return try result.get()
    }
}
