import SwiftUI
import EclipseKit
import mGBAEclipseCore

struct SettingsView: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Form {
            Section {
                NavigationLink(to: .manageTags) {
                    Text("Tags")
//                    Label("Tags", systemImage: "tag")
                }
            } header: {
                Text("Library")
            }

            Section {
                Slider(value: settings.$volume, in: 0 ... 1) {
                    Text("Volume")
                } minimumValueLabel: {
                    Label("Lower Volume", systemImage: "speaker.fill")
                        .foregroundStyle(.secondary)
                } maximumValueLabel: {
                    Label("Raise Volume", systemImage: "speaker.wave.3.fill")
                        .foregroundStyle(.secondary)
                }
                .labelStyle(.iconOnly)

                Toggle("Ignore Silent Mode", isOn: settings.$ignoreSilentMode)
            } header: {
                Text("Audio")
            } footer: {
                Text("When enabled, Ignore Silent Mode will allow game audio to keep playing when your device's Silent Mode is on.")
            }

            Section {
                ForEach(GameSystem.concreteCases, id: \.self) { system in
                    NavigationLink(to: .systemSettings(system)) {
                        Text(system.string)
                    }
                }
            } header: {
                Text("Systems")
            } footer: {
                Text("Controls and other core-related settings are on a per-system basis.")
            }

            Section {
                ForEach(coreRegistry.cores) { core in
                    NavigationLink(to: .coreSettings(core)) {
                        Text(core.name)
                    }
                }
            } header: {
                Text("Cores")
            }

            aboutSection
            socialSection

            Section {
                Button("Clear Library", role: .destructive, action: resetLibrary)
                Button("Use Default Settings", role: .destructive, action: resetSettings)
                Button("Reset All Content & Settings", role: .destructive, action: resetEverything)
            } header: {
                Text("Reset")
            }

            versionInfoSection
        }
        .navigationTitle("Settings")
        .formStyle(.grouped)
    }

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

    var aboutSection: some View {
        Section {
            Link(destination: URL(string: "https://eclipseemu.me/")!) {
                HStack {
                    Label("Help & Guides", systemImage: "questionmark")
                        .labelStyle(.titleOnly)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
            Link(destination: URL(string: "https://eclipseemu.me/")!) {
                HStack {
                    Label("What's New", systemImage: "doc.badge.clock")
                        .labelStyle(.titleOnly)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
            NavigationLink(to: .credits) {
                Label("Credits", systemImage: "person")
                    .labelStyle(.titleOnly)
            }
        } header: {
            Text("About")
        }
        .buttonStyle(.plain)
    }

    var socialSection: some View  {
        Section {
            Link(destination: URL(string: "https://discord.gg/Mx2W9nec4Z")!) {
                HStack {
                    Label("Discord", systemImage: "app.dashed")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.secondary)
                }
            }
            Link(destination: URL(string: "https://github.com/EclipseEmu")!) {
                HStack {
                    Label("GitHub", systemImage: "app.dashed")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.secondary)
                }
            }
        } header: {
            Text("Social")
        }
    }

    // FIXME: todo, make these show confirmation dialogs

    func resetLibrary() {}
    func resetSettings() {}
    func resetEverything() {}
}

#Preview {
    let settings = Settings()
    NavigationStack {
        SettingsView()
            .environmentObject(CoreRegistry(cores: [mGBACoreInfo], settings: settings))
            .environmentObject(settings)
    }
}
