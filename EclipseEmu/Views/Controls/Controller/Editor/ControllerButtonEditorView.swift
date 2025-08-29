import SwiftUI
import EclipseKit

struct ControllerButtonEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @ObservedObject private var viewModel: ControllerEditorViewModel
    private let title: LocalizedStringKey
    private let control: ControllerControl
    @State private var inputs: CoreInput
    @State private var direction: ControlMappingDirection

    init(viewModel: ControllerEditorViewModel, binding: ControllerEditorButtonElement) {
        self.viewModel = viewModel
        self.control = binding.key
        self.title = binding.key.label(for: viewModel.controlsNaming).0
        self.inputs = binding.binding?.input ?? []
        self.direction = binding.binding?.direction ?? .none
    }
    
    var body: some View {
        Form {
            Section {
                InputPickerView(inputs: $inputs, availableInputs: viewModel.system.inputs, namingConvention: viewModel.inputNaming)
                
                Picker("DIRECTION", systemImage: "chevron.compact.up.chevron.compact.right.chevron.compact.down.chevron.compact.left", selection: $direction) {
                    ForEach(ControlMappingDirection.allCases, id: \.rawValue) { direction in
                        Text(direction.label).tag(direction)
                    }
                }
            } footer: {
                Text("CONTROLS_DIRECTION_EXPLAINER")
            }
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                CancelButton(action: dismiss.callAsFunction)
            }
            ToolbarItem(placement: .confirmationAction) {
                ConfirmButton("SAVE", action: save)
            }
        }
        .navigationTitle(title)
#if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private func save() {
        viewModel.mappings.update(.init(key: control, binding: .init(inputs, direction: direction)))
        dismiss()
    }
}
