import SwiftUI

#if !os(macOS)
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: "checkmark")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.tint)
                    .opacity(configuration.isOn ? 1.0 : 0.0)
                    .scaleEffect(configuration.isOn ? 1.0 : 0.9)
            }
        }
    }
}
#endif

extension View {
    func toggleStyleCheckbox() -> some View {
#if os(macOS)
        self.toggleStyle(.checkbox)
#else
        self.toggleStyle(CheckboxToggleStyle())
#endif
    }
}
