import SwiftUI

struct EmptyStateViewModifier<EmptyContent>: ViewModifier where EmptyContent: View {
    var isEmpty: Bool
    let emptyContent: () -> EmptyContent
    
    func body(content: Content) -> some View {
        if isEmpty {
            self.emptyContent()
        } else {
            content
        }
    }
}

extension View {
    func emptyState<EmptyContent>(_ isEmpty: Bool, emptyContent: @escaping () -> EmptyContent) -> some View where EmptyContent: View {
        modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: emptyContent))
    }
    
    func emptyMessage(_ isEmpty: Bool, title: @escaping () -> Text, message: @escaping () -> Text) -> some View {
        modifier(EmptyStateViewModifier(isEmpty: isEmpty, emptyContent: {
            MessageBlock {
                title()
                    .fontWeight(.medium)
                    .padding([.top, .horizontal], 8.0)
                message()
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding([.bottom, .horizontal], 8.0)
            }
        }))
    }
}
