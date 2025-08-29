import SwiftUI
import EclipseKit

struct SettingsEmulationContentView: View {
    @EnvironmentObject private var settings: Settings
    
    var body: some View {
        Section {
            Slider(value: settings.$volume, in: 0 ... 1) {
                Text("VOLUME")
            } minimumValueLabel: {
                Label("VOLUME_DOWN", systemImage: "speaker.fill")
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Label("VOLUME_UP", systemImage: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
            .labelStyle(.iconOnly)

            Toggle("IGNORE_SILENT_MODE", isOn: settings.$ignoreSilentMode)
        } header: {
            Text("AUDIO")
        } footer: {
            Text("IGNORE_SILENT_MODE_DESCRIPTION")
        }

        Section {
            ForEach(System.concreteCases, id: \.self, content: SystemCorePickerView.init)
        } header: {
            Text("SYSTEMS")
        } footer: {
            Text("SYSTEMS_SETTINGS_CORE_SELECTION_DESCRIPTION")
        }
    }
}
