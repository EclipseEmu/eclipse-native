import SwiftUI

struct DeadZoneEditorSectionView: View {
    @Binding var deadzone: Float32
    
    init(_ deadzone: Binding<Float32>) {
        self._deadzone = deadzone
    }
    
    var body: some View {
        Section {
            LabeledContent {
                Text(deadzone, format: .number.precision(.fractionLength(2...2)))
                    .font(.body.monospaced())
            } label: {
                Label("DEAD_ZONE", systemImage: "smallcircle.circle")
            }
            Slider(value: $deadzone, in: 0.25...0.95, step: 0.05) {}
                .labelsHidden()
        } footer: {
            Text("DEAD_ZONE_EXPLAINER")
        }
    }
}
