import Foundation

/// A boxed reference to the underlying value, a la Rust (useful for enums with associated values to enforce a size)
final class Box<T> {
    var value: T
    
    init(_ value: T) {
        self.value = value
    }
}
