import SwiftUI
import CoreData

struct RenameConfirmationViewModifier: ViewModifier {
    let titleKey: LocalizedStringKey
    @Binding var isPresented: Bool
    let perform: (String) -> Void
    @State private var newName: String = ""

    func body(content: Content) -> some View {
        content
            .alert(titleKey, isPresented: $isPresented) {
                TextField("NEW_NAME", text: $newName)
                Button("CANCEL", role: .cancel) {}
                Button("RENAME", action: confirm)
                    .disabled(newName.isEmpty)
            }
    }

    private func confirm() {
        perform(newName)
    }
}

struct RenameItemViewModifier<T: RenameableObject>: ViewModifier {
    let titleKey: LocalizedStringKey

    @Binding var item: T?
    @State private var newName: String = ""
    @EnvironmentObject var persistence: Persistence

    func body(content: Content) -> some View {
        content
            .modifier(RenameConfirmationViewModifier(titleKey: titleKey, isPresented: .isSome($item), perform: perform))
    }

    private func perform(newName: String) {
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
    func renameItem(
        _ titleKey: LocalizedStringKey,
        isPresented: Binding<Bool>,
        perform: @escaping (String) -> Void
    ) -> some View {
        modifier(RenameConfirmationViewModifier(titleKey: titleKey, isPresented: isPresented, perform: perform))
    }
    
    func renameItem<T: RenameableObject>(_ titleKey: LocalizedStringKey, item: Binding<T?>) -> some View {
        modifier(RenameItemViewModifier(titleKey: titleKey, item: item))
    }
}
