import SwiftUI
import EclipseKit

struct ControllerDirectionalEditorView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    
    @ObservedObject private var viewModel: ControllerEditorViewModel
    private let title: LocalizedStringKey
    private let control: ControllerControl
    @State private var inputs: CoreInput
    @State private var deadzone: Float32

    init(viewModel: ControllerEditorViewModel, binding: ControllerEditorDirectionalElement) {
        self.viewModel = viewModel
        self.control = binding.key
        self.title = binding.key.label(for: viewModel.controlsNaming).0
        self.inputs = binding.binding?.input ?? []
        self.deadzone = binding.binding?.deadzone ?? 0.5
    }
     
    var body: some View {
        Form {
            Section {
                Picker("INPUT", systemImage: "dpad", selection: $inputs) {
                    Text("NONE").tag(CoreInput())
                    Divider()
                    ForEach(CoreInput.directionalInputs(for: viewModel.system), id: \.rawValue) { input in
                        let (text, image) = input.label(for: viewModel.inputNaming)
                        Label(text, systemImage: image).tag(input)
                    }
                }
            }
            
            DeadZoneEditorSectionView($deadzone)
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
        viewModel.mappings.update(.init(key: control, binding: .init(input: inputs, deadzone: deadzone)))
        dismiss()
    }
}
