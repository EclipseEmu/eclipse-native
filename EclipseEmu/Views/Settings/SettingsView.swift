import SwiftUI
import EclipseKit

struct SettingsView: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Form {
			aboutSection
			
			Section {
				#if canImport(UIKit)
				NavigationLink(to: .touchProfiles) {
                    Text("TOUCH")
                }
				#endif
                NavigationLink(to: .keyboardProfiles) {
                    Text("KEYBOARD")
                }
                NavigationLink(to: .controllerProfiles) {
                    Text("CONTROLLERS")
                }
            } header: {
                Text("CONTROLS")
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
                ForEach(System.concreteCases, id: \.self) { system in
                    SystemSettingItemView(
                        coreRegistry: coreRegistry,
                        system: system
                    )
                }
            } header: {
                Text("SYSTEMS")
            } footer: {
                Text("SYSTEMS_SETTINGS_CORE_SELECTION_DESCRIPTION")
            }

            Section {
				ForEach(Core.allCases) { core in
                    NavigationLink(to: .coreSettings(core)) {
						Text(core.type.name)
                    }
                }
            } header: {
                Text("CORES")
            }

            socialSection

            Section {
                Button("RESET_SETTINGS", role: .destructive, action: resetSettings)
                Button("RESET_EVERYTHING", role: .destructive, action: resetEverything)
            } header: {
                Text("RESET")
            }

#if !os(macOS)
            versionInfoSection
#endif
        }
        .navigationTitle("SETTINGS")
        .formStyle(.grouped)
    }

	#if !os(macOS)
	var versionInfoSection: some View {
        Section {} footer: {
            VStack(alignment: .center) {
                Rectangle()
                    .overlay { AppIconView() }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 11.0))
                Text("v\(Bundle.main.releaseVersionNumber ?? "") (\(Bundle.main.buildVersionNumber ?? ""))")
            }.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        }
    }
	#endif

    var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://eclipseemu.me/")!) {
                HStack {
                    Label("HELP_AND_GUIDES", systemImage: "questionmark")
                        .labelStyle(.titleOnly)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
            Link(destination: URL(string: "https://eclipseemu.me/")!) {
                HStack {
                    Label("WHATS_NEW", systemImage: "doc.badge.clock")
                        .labelStyle(.titleOnly)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
            NavigationLink(to: .credits) {
                Label("CREDITS", systemImage: "person")
                    .labelStyle(.titleOnly)
            }
        } header: {
            Text("ABOUT")
        }
        .buttonStyle(.plain)
    }

    var socialSection: some View  {
        Section {
            Link(destination: URL(string: "https://discord.gg/Mx2W9nec4Z")!) {
                HStack {
                    Label("DISCORD", systemImage: "app.dashed")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.secondary)
                }
            }
            Link(destination: URL(string: "https://github.com/EclipseEmu")!) {
                HStack {
                    Label("GITHUB", systemImage: "app.dashed")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.secondary)
                }
            }
        } header: {
            Text("SOCIAL")
        }
    }

    // FIXME: todo, make these show confirmation dialogs

    func resetSettings() {}
    func resetEverything() {}
}

#Preview {
    let settings = Settings()
    NavigationStack {
        SettingsView()
            .environmentObject(CoreRegistry())
            .environmentObject(settings)
    }
}
