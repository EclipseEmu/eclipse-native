import SwiftUI
import CoreData

struct DeleteItemViewModifier<T: NSManagedObject>: ViewModifier {
    @EnvironmentObject private var persistence: Persistence
    let titleKey: LocalizedStringKey
    @Binding var item: T?
    let dismiss: Bool
    let message: (T) -> Text
    @Environment(\.dismiss) var dismissAction: DismissAction

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                titleKey,
                isPresented: .isNotNullish($item),
                presenting: item
            ) { _ in
                Button("Delete", role: .destructive, action: perform)
            } message: { value in
                message(value)
            }
    }

    private func perform() {
        guard let item else { return }
        Task {
            do {
                try await persistence.objects.delete(.init(item))
                if dismiss {
                    dismissAction()
                }
            } catch {
                // FIXME: handle error
                print(error)
            }
        }
    }
}

extension View {
    func deleteItem<T: NSManagedObject>(
        _ titleKey: LocalizedStringKey,
        item: Binding<T?>,
        dismiss: Bool = false,
        message: @escaping (T) -> Text
    ) -> some View {
        modifier(DeleteItemViewModifier(titleKey: titleKey, item: item, dismiss: dismiss, message: message))
    }
}
