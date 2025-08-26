import SwiftUI

extension Binding {
    @MainActor
    static func isSome<T>(_ value: Binding<T?>) -> Binding<Bool> {
        .init(
            get: { value.wrappedValue != nil },
            set: { value.wrappedValue = $0 ? value.wrappedValue : nil }
        )
    }
    
    @MainActor
    static func isInSet<T>(_ value: T, set: Binding<Set<T>>) -> Binding<Bool> {
        .init(
            get: { set.wrappedValue.contains(value) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.15)) {
                    set.wrappedValue.toggle(value, if: newValue)
                }
            }
        )
    }
    
    @MainActor
    static func isInSet<T: OptionSet>(_ value: T.Element, set: Binding<T>) -> Binding<Bool> {
        .init(
            get: { set.wrappedValue.contains(value) },
            set: { newValue in
                withAnimation(.easeInOut(duration: 0.15)) {
                    if newValue {
                        set.wrappedValue.insert(value)
                    } else {
                        set.wrappedValue.remove(value)
                    }
                }
            }
        )
    }
}
