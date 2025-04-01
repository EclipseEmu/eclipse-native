/// A boxed reference to the underlying value, a la Rust (useful for enums with associated values to enforce a size)
final class Box<T> {
    var value: T

    init(_ value: T) {
        self.value = value
    }
}

extension Box: Equatable where T: Equatable {
    static func == (lhs: Box<T>, rhs: Box<T>) -> Bool {
        lhs.value == rhs.value
    }
}

extension Box: Hashable where T: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}
