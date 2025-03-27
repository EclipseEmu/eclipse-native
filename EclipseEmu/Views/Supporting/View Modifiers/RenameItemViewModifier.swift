import SwiftUI
import CoreData

struct RenameItemViewModifier<T: RenameableObject>: ViewModifier {
    let titleKey: LocalizedStringKey

    @Binding var item: T?
    @State private var newName: String = ""
    @EnvironmentObject var persistence: Persistence

    func body(content: Content) -> some View {
        content
            .alert(titleKey, isPresented: .isNotNullish($item)) {
                TextField("New Name", text: $newName)
                Button("Cancel", role: .cancel) {}
                Button("Rename", action: perform)
                    .disabled(newName.isEmpty)
            }
    }

    private func perform() {
        guard let item else { return }
        Task {
            do {
                try await persistence.objects.rename(.init(item), to: newName)
            } catch {
                // FIXME: handle error
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
