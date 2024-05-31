import SwiftUI
import CoreData

struct RenameViewModifier<T: NSManagedObject>: ViewModifier {
    @Binding var target: T?
    @State var isOpen: Bool = false
    @State var text: String = ""
    let title: LocalizedStringKey
    let placeholder: LocalizedStringKey
    let keyPath: KeyPath<T, String?>
    let onChange: (T, String) -> Void

    init(
        target: Binding<T?>,
        keyPath: KeyPath<T, String?>,
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        onChange: @escaping (T, String) -> Void
    ) {
        self._target = target
        self.keyPath = keyPath
        self.title = title
        self.placeholder = placeholder
        self.onChange = onChange
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: target, perform: self.targetChanged(newTarget:))
            .alert(title, isPresented: $isOpen) {
                TextField(placeholder, text: $text)
                Button("Cancel", role: .cancel, action: self.cancel)
                Button("Rename", action: self.rename)
            }
    }

    func targetChanged(newTarget: T?) {
        if let newTarget {
            self.text = newTarget[keyPath: self.keyPath] ?? ""
            self.isOpen = true
        } else {
            self.text = ""
            self.isOpen = false
        }
    }

    func cancel() {
        self.target = nil
    }

    func rename() {
        guard let target else { return }
        self.onChange(target, self.text)
        self.target = nil
    }
}

extension View {
    func renameAlert<T: NSManagedObject>(
        _ target: Binding<T?>,
        key: KeyPath<T, String?>,
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        onChange: @escaping (T, String) -> Void
    ) -> some View {
        modifier(
            RenameViewModifier(target: target, keyPath: key, title: title, placeholder: placeholder, onChange: onChange)
        )
    }
}
