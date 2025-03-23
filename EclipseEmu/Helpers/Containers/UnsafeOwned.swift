struct UnsafeOwned<T>: ~Copyable, @unchecked Sendable {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}
