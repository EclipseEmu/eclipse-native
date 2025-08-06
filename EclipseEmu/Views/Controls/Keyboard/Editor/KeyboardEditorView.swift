import SwiftUI
import EclipseKit
import GameController

struct KeyboardEditorView: View {
    @StateObject private var viewModel: KeyboardEditorViewModel
    let namingConvention: ControlNamingConvention
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
                    Button {
                        self.editTarget = .create
                    } label: {
                        Label("ADD_BINDING", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editTarget) { target in
                NavigationStack {
                    KeyboardElementEditorView(viewModel: viewModel, target: target)
                }
            }
    }
    
    @ViewBuilder
    var content: some View {
        if viewModel.elements.isEmpty {
            ContentUnavailableMessage {
                Label("NO_KEYBINDINGS_TITLE", systemImage: "keyboard")
            } description: {
                Text("NO_KEYBINDINGS_MESSAGE")
            }
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
