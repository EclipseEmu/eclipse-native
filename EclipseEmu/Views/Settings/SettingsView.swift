import SwiftUI
import EclipseKit

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Form {
			Section("CONTROLS") {
				#if canImport(UIKit)
				NavigationLink("TOUCH", to: .touchProfiles)
				#endif
                NavigationLink("KEYBOARD", to: .keyboardProfiles)
                NavigationLink("CONTROLLERS", to: .controllerProfiles)
            }

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

            Section("CORES") {
				ForEach(Core.allCases) { core in
                    NavigationLink(verbatim: core.type.name, to: .coreSettings(core))
                }
            }

            Section("ABOUT") {
                NavigationLink("CREDITS", systemImage: "person", to: .credits)
                LinkItemView("HELP_AND_GUIDES", systemImage: "questionmark", to: URL(string: "https://eclipseemu.me/")!)
                LinkItemView("WHATS_NEW", systemImage: "doc.badge.clock", to: URL(string: "https://eclipseemu.me/")!)
                LinkItemView("DISCORD", systemImage: "app.dashed", to: URL(string: "https://discord.gg/Mx2W9nec4Z")!)
                LinkItemView("GITHUB", systemImage: "app.dashed", to: URL(string: "https://github.com/EclipseEmu")!)
            }
            .buttonStyle(.borderless)
            .labelStyle(.titleOnly)

#if !os(macOS)
            Section {} footer: {
                versionInfoSection
            }
#endif
        }
        .navigationTitle("SETTINGS")
        .formStyle(.grouped)
    }

	#if !os(macOS)
	var versionInfoSection: some View {
        VStack(alignment: .center) {
            Rectangle()
                .overlay { AppIconView() }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 11.0))
            Text("v\(Bundle.main.releaseVersionNumber ?? "") (\(Bundle.main.buildVersionNumber ?? ""))")
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
    }
	#endif
}

#Preview {
    let settings = Settings()
    NavigationStack {
        SettingsView()
            .environmentObject(CoreRegistry())
            .environmentObject(settings)
    }
}
