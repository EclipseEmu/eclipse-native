import SwiftUI
import CoreData

struct RenameItemViewModifier<T: RenameableObject>: ViewModifier {
    let titleKey: LocalizedStringKey

    @Binding var item: T?
    @State private var newName: String = ""
    @EnvironmentObject var persistence: Persistence

    func body(content: Content) -> some View {
        content
            .alert(titleKey, isPresented: .isSome($item)) {
                TextField("NEW_NAME", text: $newName)
                Button("CANCEL", role: .cancel) {}
                Button("RENAME", action: perform)
                    .disabled(newName.isEmpty)
            }
    }

    private func perform() {
        guard let item else { return }
        Task {
            do {
                try await persistence.objects.rename(.init(item), to: newName)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}

extension View {
    func renameItem<T: RenameableObject>(_ titleKey: LocalizedStringKey, item: Binding<T?>) -> some View {
        modifier(RenameItemViewModifier(titleKey: titleKey, item: item))
    }
}
