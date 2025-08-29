import SwiftUI
import EclipseKit
import GameController

struct KeyboardElementEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction

    @ObservedObject private var viewModel: KeyboardEditorViewModel
    private let index: Int?
    private let initialKeycode: GCKeyCode?
    @State private var keycode: GCKeyCode?
    @State private var mapping: KeyboardMapping
    @State private var isAddInputPopoverOpen = false
    @State private var isDuplicate = false
    
    init(viewModel: KeyboardEditorViewModel, target: EditorTarget<Int>) {
        self.viewModel = viewModel
        switch target {
        case .create:
            self.index = nil
            self.initialKeycode = nil
            self.keycode = nil
            self.mapping = .init([], direction: .none)
        case .edit(let index):
            let element = viewModel.elements[index]
            self.index = index
            self.initialKeycode = element.keycode
            self.keycode = element.keycode
            self.mapping = element.mapping
        }
    }
    
    var body: some View {
        Form {
            Section {
                LabeledContent {
                    KeyboardEditorKeyInputView(keycode: $keycode, isDuplicate: $isDuplicate)
                } label: {
                    Label("KEY", systemImage: "keyboard")
                }
            } footer: {
                Text("CONTROLS_KEY_INPUT_EXPLAINER")
            }
            
            Section {
                InputPickerView(inputs: $mapping.input, availableInputs: viewModel.system.inputs, namingConvention: self.viewModel.namingConvention)
                
                Picker(
                    "DIRECTION",
                    systemImage: "chevron.compact.up.chevron.compact.right.chevron.compact.down.chevron.compact.left",
                    selection: $mapping.direction
                ) {
                    ForEach(ControlMappingDirection.allCases, id: \.rawValue) { direction in
                        Text(direction.label).tag(direction)
                    }
                }
            } footer: {
                Text("CONTROLS_DIRECTION_EXPLAINER")
            }
        }
        .onChange(of: keycode, perform: checkDuplicate)
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                CancelButton("CANCEL", action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .confirmationAction) {
                ConfirmButton("SAVE", action: save)
                    .disabled(keycode == nil || mapping.input == [] || isDuplicate)
            }
        }
    }
    
    private func checkDuplicate(newKey: GCKeyCode?) {
        guard let newKey else { return }
        self.isDuplicate = viewModel.isDuplicate(old: initialKeycode, new: newKey)
    }
    
    private func save() {
        guard let keycode else { return }
        if let index {
            viewModel.updateElement(index, keycode: keycode, mapping: mapping)
        } else {
            viewModel.insertElement(keycode: keycode, mapping: mapping)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        KeyboardElementEditorView(viewModel: .init(onChange: { _ in }, bindings: [GCKeyCode.upArrow:.init(.dpad, direction: .fullPositiveY)], system: .gba), target: .create)
    }
}
