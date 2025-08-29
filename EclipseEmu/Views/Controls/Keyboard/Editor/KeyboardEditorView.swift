import SwiftUI
import EclipseKit
import GameController

struct KeyboardEditorView: View {
    @StateObject private var viewModel: KeyboardEditorViewModel
    private let namingConvention: ControlNamingConvention
    @FocusState private var focusState: KeyboardEditorElement?
    @State private var editTarget: EditorTarget<Int>?
    
    init(
        onChange: @escaping ControlsProfileUpdateCallback<InputSourceKeyboardDescriptor>,
        bindings: KeyboardMappings,
        system: System
    ) {
        self.namingConvention = system.controlNamingConvention
        self._viewModel = StateObject(wrappedValue: {
            .init(onChange: onChange, bindings: bindings, system: system)
        }())
    }
    
    var body: some View {
        self.content
            .toolbar {
                ToolbarItem {
                    Button("ADD_BINDING", systemImage: "plus") {
                        self.editTarget = .create
                    }
                }
            }
            .sheet(item: $editTarget) { target in
                FormSheetView {
                    KeyboardElementEditorView(viewModel: viewModel, target: target)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.elements.isEmpty {
            ContentUnavailableMessage("NO_KEYBINDINGS_TITLE", systemImage: "keyboard", description: "NO_KEYBINDINGS_MESSAGE")
        } else {
            List {
                ForEach(viewModel.elements) { element in
                    KeyboardEditorElementView(element, viewModel: viewModel, editTarget: $editTarget)
                }
                .onDelete(perform: viewModel.deleteElements)
            }
            .formStyle(.grouped)
        }
    }
}

#Preview {
    NavigationStack {
        KeyboardEditorView(onChange: { _ in }, bindings: [:], system: .gba)
    }
}
