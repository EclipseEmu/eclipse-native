import SwiftUI
import CoreData

private struct DeleteConfirmationViewModifier: ViewModifier {
    let titleKey: LocalizedStringKey
    @Binding var isPresented: Bool
    let message: () -> Text
    let perform: () async -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(titleKey, isPresented: $isPresented) {
                Button("DELETE", role: .destructive, action: action)
            } message: {
                message()
            }
    }

    func action() {
        Task {
            await perform()
        }
    }
}

extension View {
    func deleteItem(
        _ titleKey: LocalizedStringKey,
        isPresented: Binding<Bool>,
        perform: @escaping () async -> Void,
        message: @escaping () -> Text
    ) -> some View {
        modifier(DeleteConfirmationViewModifier(
            titleKey: titleKey,
            isPresented: isPresented,
            message: message,
            perform: perform
        ))
    }
}
