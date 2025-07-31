import Foundation
import AtomicCompat
import EclipseKit

private final class Future<T: ~Copyable, Err: Error>: Sendable {
	private let state: Atomic<Bool> = .init(false)
	private nonisolated(unsafe) var value: Result<T, Err>?

	func resume(with result: consuming Result<T, Err>) -> Void {
		unsafe self.value = consume result
		self.state.store(true, ordering: .relaxed)
	}

	@inlinable
	func resume(returning value: consuming T) -> Void {
		self.resume(with: .success(value))
	}

	@inlinable
	func resume(throwing error: consuming Err) -> Void {
		self.resume(with: .failure(error))
	}

	func wait() async throws(Err) -> T {
		while !self.state.exchange(false, ordering: .relaxed) {
			await Task.yield()
		}
		let value = unsafe self.value.take()!
		return try value.get()
	}
}

final class SingleThreadedExecutor: SerialExecutor, @unchecked Sendable {
	private let keepAlive: ManagedAtomic<Bool>
	private let thread: Thread
	private let runLoop: RunLoop

	@usableFromInline
	var isIsolated: Bool {
		thread == Thread.current
	}

	init(name: String, qos: QualityOfService) async {
		let keepAlive = ManagedAtomic(true)
		let future: Future<UnsafeSend<RunLoop>, Never> = unsafe Future()
		thread = Thread {
			let current = RunLoop.current
			unsafe future.resume(returning: UnsafeSend(current))

			while keepAlive.load(ordering: .relaxed) {
				current.run(mode: .default, before: .distantFuture)
			}
		}
		thread.name = name
		thread.qualityOfService = qos
		thread.start()

		self.keepAlive = keepAlive
		runLoop = unsafe await future.wait().inner
	}

	deinit {
		keepAlive.store(false, ordering: .relaxed)
	}

	func enqueue(_ job: UnownedJob) {
		runLoop.perform {
			unsafe job.runSynchronously(on: self.asUnownedSerialExecutor())
		}
	}

	func asUnownedSerialExecutor() -> UnownedSerialExecutor {
		unsafe UnownedSerialExecutor(ordinary: self)
	}

	func checkIsolated() {
		precondition(isIsolated)
	}

	func run<T: ~Copyable & Sendable, Err: Error>(_ block: @escaping @Sendable () throws(Err) -> sending T) async throws(Err) -> T {
		let future = Future<T, Err>()
		runLoop.perform {
			do {
				let result = try block()
				future.resume(returning: result)
			} catch {
				future.resume(throwing: error as! Err)
			}
		}
		return try await future.wait()
	}

	@inlinable
	func addTimer(_ timer: some DisplayLinkProtocol, forMode mode: RunLoop.Mode) {
		timer.add(to: self.runLoop, forMode: mode)
	}
}
