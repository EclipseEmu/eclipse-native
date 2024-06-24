import Foundation

/// A boxed reference to the underlying value, a la Rust.
final class Box<T> {
    var value: T

    init(_ value: T) {
        self.value = value
    }
}
