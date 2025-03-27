import SwiftUI

extension Binding {
    @MainActor
    static func isNotNullish<T>(_ value: Binding<T?>) -> Binding<Bool> {
        .init(
            get: { value.wrappedValue != nil },
            set: { value.wrappedValue = $0 ? value.wrappedValue : nil }
        )
    }
}
