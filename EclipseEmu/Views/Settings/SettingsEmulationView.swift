import SwiftUI

struct SettingsEmulationView: View {
    @State var isAudioEnabled = false
    @State var isIgnoreSilentModeEnabled = false
    @State var volume: Float16 = 0.6

    var body: some View {
        Form {
            Section {
                Toggle("Audio Enabled", isOn: $isAudioEnabled)
                Slider(value: $volume, in: 0 ... 1) {} minimumValueLabel: {
                    Label("Lower Volume", systemImage: "speaker")
                } maximumValueLabel: {
                    Label("Raise Volume", systemImage: "speaker.wave.3")
                }.labelStyle(.iconOnly).disabled(!isAudioEnabled)
            }

            Section {
                Toggle("Ignore Silent Mode", isOn: $isIgnoreSilentModeEnabled)
            } footer: {
                Text("When enabled, game audio will play with your device's Silent Mode on.")
            }
            #if os(macOS)
            Spacer()
            #endif
        }
        .navigationTitle("Emulation")
    }
}

#Preview {
    SettingsEmulationView()
}
