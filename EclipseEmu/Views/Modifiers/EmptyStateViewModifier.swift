import SwiftUI

struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
    var isEmpty: Bool
    let emptyContent: () -> EmptyContent

    func body(content: Content) -> some View {
        if isEmpty {
            emptyContent()
        } else {
            content
        }
    }
}

extension View {
    func isHidden(_ isEmpty: Bool) -> some View {
        modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: { EmptyView() }))
    }

    func emptyState<EmptyContent>(
        _ isEmpty: Bool,
        emptyContent: @escaping () -> EmptyContent
    ) -> some View where EmptyContent: View {
        modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
    }
}
