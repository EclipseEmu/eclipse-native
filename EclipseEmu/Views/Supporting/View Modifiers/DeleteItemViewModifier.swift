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

private struct DeleteItemViewModifier<T>: ViewModifier {
    let titleKey: LocalizedStringKey
    @Binding var item: T?
    let message: (T) -> Text
    let perform: (T) async -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                titleKey,
                isPresented: .isSome($item),
                presenting: item
            ) { _ in
                Button("DELETE", role: .destructive, action: action)
            } message: { value in
                message(value)
            }
    }

    func action() {
        guard let item else { return }
        Task {
            await perform(item)
        }
    }
}

private struct DeleteObjectViewModifier<T: NSManagedObject>: ViewModifier {
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.dismiss) private var dismissAction: DismissAction

    let titleKey: LocalizedStringKey
    @Binding var item: T?
    let dismiss: Bool
    let message: (T) -> Text

    func body(content: Content) -> some View {
        content.modifier(DeleteItemViewModifier(titleKey: titleKey, item: $item, message: message, perform: perform))
    }

    private func perform(item: T) async {
        do {
            try await persistence.objects.delete(.init(item))
            if dismiss {
                dismissAction()
            }
        } catch {
            // FIXME: Surface error
            print(error)
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

    func deleteItem<T>(
        _ titleKey: LocalizedStringKey,
        item: Binding<T?>,
        message: @escaping (T) -> Text,
        perform: @escaping (T) async -> Void
    ) -> some View {
        modifier(DeleteItemViewModifier(titleKey: titleKey, item: item, message: message, perform: perform))
    }

    func deleteItem<T: NSManagedObject>(
        _ titleKey: LocalizedStringKey,
        item: Binding<T?>,
        dismiss: Bool = false,
        message: @escaping (T) -> Text
    ) -> some View {
        modifier(DeleteObjectViewModifier(titleKey: titleKey, item: item, dismiss: dismiss, message: message))
    }
}
