import SwiftUI

fileprivate struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                configuration.icon
                    .imageScale(.medium)
                    .foregroundColor(.white).padding(6.0)
                    .aspectRatio(1.0, contentMode: .fit)
            }
            .frame(width: 36, height: 36)
            .background(RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.black)
            .padding(.trailing, 4.0)
            .padding(.vertical, 1.0)
            configuration.title
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        CompatNavigationStack {
            List {
                Section {
                    NavigationLink(destination: SettingsGeneralView()) {
                        Label("General", systemImage: "gear")
                            .labelStyle(SettingsLabelStyle())
                    }
                    NavigationLink(destination: SettingsEmulationView()) {
                        Label("Emulation", systemImage: "cpu.fill")
                            .labelStyle(SettingsLabelStyle())
                    }
                    NavigationLink(destination: SettingsControlsView()) {
                        Label("Controls", systemImage: "gamecontroller.fill")
                            .labelStyle(SettingsLabelStyle())
                    }
                }
                
                Section {
                    Link(destination: URL(string: "https://eclipseemu.me/")!) {
                        HStack {
                            Label("Help & Guides", systemImage: "questionmark")
                                .labelStyle(SettingsLabelStyle())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://eclipseemu.me/")!) {
                        HStack {
                            Label("What's New", systemImage: "sparkle")
                                .labelStyle(SettingsLabelStyle())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://eclipseemu.me/")!) {
                        HStack {
                            Label("Credits", systemImage: "person.fill")
                                .labelStyle(SettingsLabelStyle())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }.buttonStyle(.plain)
                
                Section {
                    Link(destination: URL(string: "https://discord.gg/Mx2W9nec4Z")!) {
                        HStack {
                            Label("Discord", systemImage: "app.dashed")
                                .labelStyle(SettingsLabelStyle())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: URL(string: "https://github.com/EclipseEmu")!) {
                        HStack {
                            Label("GitHub", systemImage: "app.dashed")
                                .labelStyle(SettingsLabelStyle())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }.buttonStyle(.plain)
                
                Section {
                    Button(role: .destructive) {} label: {
                        Text("Reset Library")
                    }
                    Button(role: .destructive) {} label: {
                        Text("Reset Controls")
                    }
                    Button(role: .destructive) {} label: {
                        Text("Reset Settings")
                    }
                    Button(role: .destructive) {} label: {
                        Text("Reset All Content & Settings")
                    }
                }
                
                Section {} footer: {
                    VStack(alignment: .center) {
                        Rectangle()
                            .overlay { AppIconView() }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 11.0))
                        Text("v\(Bundle.main.releaseVersionNumber ?? "") (\( Bundle.main.buildVersionNumber ?? ""))")
                    }.frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
