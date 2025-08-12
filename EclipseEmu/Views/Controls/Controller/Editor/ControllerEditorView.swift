import SwiftUI
import EclipseKit
import GameController

final class ControllerEditorViewModel: ObservableObject {
    let onChange: ControlsProfileUpdateCallback<InputSourceControllerDescriptor>
    let system: System
    @Published var inputNaming: ControlNamingConvention
    @Published var controlsNaming: ControllerButtonNaming = .xbox
    @Published var mappings: ControllerEditorExtendedProfile {
        didSet { onChange(.init(from: mappings)) }
    }

    init(
        onChange: @escaping ControlsProfileUpdateCallback<InputSourceControllerDescriptor>,
        bindings: ControllerMappings,
        system: System
    ) {
        self.onChange = onChange
        self.system = system
        self.inputNaming = system.controlNamingConvention
        self.mappings = .init(from: bindings)
    }
}

struct ControllerEditorElementItemView<Value: ControllerEditorElement>: View {
    private let key: WritableKeyPath<ControllerEditorExtendedProfile, Value>
    @Binding private var editTarget: Value?
    @ObservedObject private var viewModel: ControllerEditorViewModel

    init(_ control: WritableKeyPath<ControllerEditorExtendedProfile, Value>, editTarget: Binding<Value?>, viewModel: ControllerEditorViewModel) {
        self.key = control
        self._editTarget = editTarget
        self.viewModel = viewModel
    }
    
    var body: some View {
        EditableContent(action: self.edit) {
            let (name, icon) = viewModel.mappings[keyPath: self.key].key.label(for: viewModel.controlsNaming)
            Label {
                Text(name)
                valueLabel
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: icon)
            }
        }
    }
    
    @ViewBuilder
    var valueLabel: some View {
        if let binding = viewModel.mappings[keyPath: self.key].label(inputNaming: viewModel.inputNaming) {
            Text(binding)
        } else {
            Text("NONE")
        }
    }
    
    func edit() {
        self.editTarget = viewModel.mappings[keyPath: self.key]
    }
}

struct ControllerEditorView: View {
    @StateObject private var viewModel: ControllerEditorViewModel
    @State private var buttonEditTarget: ControllerEditorButtonElement?
    @State private var directionalEditTarget: ControllerEditorDirectionalElement?
    
    init(
        onChange: @escaping ControlsProfileUpdateCallback<InputSourceControllerDescriptor>,
        bindings: ControllerMappings,
        system: System
    ) {
        self._viewModel = StateObject(wrappedValue: {
            .init(onChange: onChange, bindings: bindings, system: system)
        }())
    }

    var body: some View {
        Form {
            Section {
                ControllerEditorElementItemView(\.directionPad, editTarget: $directionalEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.leftThumbstick, editTarget: $directionalEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.leftThumbstickButton, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.rightThumbstick, editTarget: $directionalEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.rightThumbstickButton, editTarget: $buttonEditTarget, viewModel: viewModel)
            }

            Section {
                ControllerEditorElementItemView(\.buttonA, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.buttonB, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.buttonX, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.buttonY, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.leftShoulder, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.leftTrigger, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.rightShoulder, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.rightTrigger, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.buttonMenu, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.buttonOptions, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.buttonHome, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.buttonShare, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.xboxPaddleOne, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.xboxPaddleTwo, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.xboxPaddleThree, editTarget: $buttonEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.xboxPaddleFour, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
            
            Section {
                ControllerEditorElementItemView(\.dualShockTouchpadOne, editTarget: $directionalEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.dualShockTouchpadTwo, editTarget: $directionalEditTarget, viewModel: viewModel)
                ControllerEditorElementItemView(\.dualShockTouchpadButton, editTarget: $buttonEditTarget, viewModel: viewModel)
            }
        }
        .formStyle(.grouped)
        .sheet(item: $buttonEditTarget) { button in
            FormSheetView {
                ControllerButtonEditorView(viewModel: viewModel, binding: button)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $directionalEditTarget) { button in
            FormSheetView {
                ControllerDirectionalEditorView(viewModel: viewModel, binding: button)
            }
            .presentationDetents([.medium, .large])
        }
        .toolbar {
            Menu {
                Picker(selection: $viewModel.controlsNaming) {
                    Text("CONTROLLER_XBOX").tag(ControllerButtonNaming.xbox)
                    Text("CONTROLLER_NINTENDO").tag(ControllerButtonNaming.nintendo)
                    Text("CONTROLLER_PLAYSTATION").tag(ControllerButtonNaming.playstation)
                } label: {}
                .labelsHidden()
            } label: {
                Label("CONTROL_NAMES", systemImage: "textformat")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ControllerEditorView(
            onChange: { _ in },
            bindings: .init(bindings: [:], buttons: [], directionals: []),
            system: .gba
        )
        .navigationTitle("Controller")
    }
}
