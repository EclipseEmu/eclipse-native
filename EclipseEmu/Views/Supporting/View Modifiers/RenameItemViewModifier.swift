import SwiftUI
import CoreData

struct RenameItemViewModifier<Object: RenameableObject>: ViewModifier {
    @EnvironmentObject var persistence: Persistence

    private let titleKey: LocalizedStringKey
    @ObservedObject private var item: Object
    @State private var newName: String
    @Binding private var isPresented: Bool
    
    init(_ titleKey: LocalizedStringKey, item: Object, isPresented: Binding<Bool>) {
        self.titleKey = titleKey
        self.item = item
        self.newName = item.name ?? ""
        self._isPresented = isPresented
    }
    
    func body(content: Content) -> some View {
        content
            .alert(titleKey, isPresented: $isPresented) {
                TextField("NEW_NAME", text: $newName)
                Button("CANCEL", role: .cancel, action: cancel)
                Button("RENAME", action: confirm)
                    .disabled(newName.isEmpty)
            }
    }
    
    private func cancel() {
        newName = item.name ?? ""
    }
    
    private func confirm() {
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
    func renameItem<T: RenameableObject>(_ titleKey: LocalizedStringKey, item: T, isPresented: Binding<Bool>) -> some View {
        modifier(RenameItemViewModifier(titleKey, item: item, isPresented: isPresented))
    }
}
