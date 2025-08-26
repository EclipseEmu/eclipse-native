import AtomicCompat

/// A runtime-unique identifier. Only valid for the lifetime of the program.
struct RuntimeUID: Hashable {
    private static let counter: Atomic<UInt> = .init(0)
    private let value: UInt

    init() {
        self.value = Self.counter.loadThenWrappingIncrement(ordering: .relaxed)
    }
}
