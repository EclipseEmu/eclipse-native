import SwiftUI
import EclipseKit

struct InputPickerView: View {
    @Binding var inputs: CoreInput
    let availableInputs: CoreInput
    let namingConvention: ControlNamingConvention
    
    @State private var isOpen = false
    
    init(inputs: Binding<CoreInput>, availableInputs: CoreInput, namingConvention: ControlNamingConvention) {
        self._inputs = inputs
        self.availableInputs = availableInputs
        self.namingConvention = namingConvention
    }
    
    var body: some View {
        LabeledContent {
            ToggleButton("SELECT", value: $isOpen)
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .popover(isPresented: $isOpen) {
                    InputPickerPopoverView(inputs: $inputs, availableInputs: availableInputs, namingConvention: namingConvention)
                        .presentationDragIndicator(.visible)
                        .presentationDetents([.medium, .large])
                        .frame(minWidth: 300, minHeight: 300)
                }
        } label: {
            Label {
                VStack(alignment: .leading) {
                    Text("INPUT")
                    let (text, _) = inputs.label(for: namingConvention)
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: "circle")
            }
        }
    }
}

private struct InputPickerPopoverView: View {
    @Binding var inputs: CoreInput
    let availableInputs: CoreInput
    let namingConvention: ControlNamingConvention
    
    var body: some View {
        Form {
            ForEach(availableInputs, id: \.rawValue) { input in
                let (text, icon) = input.label(for: namingConvention)
                Toggle(isOn: .isInSet(input, set: $inputs)) {
                    Label(text, systemImage: icon)
                }
            }
        }
        .formStyle(.grouped)
#if os(macOS)
        .toggleStyle(.checkbox)
#endif
    }
}

@available(iOS 17.0, macOS 14.0, *)
#Preview {
    @Previewable @State var input: CoreInput = []
    Form {
        InputPickerView(inputs: $input, availableInputs: CoreInput.allOn, namingConvention: .nintendo)
    }
    .formStyle(.grouped)
}
