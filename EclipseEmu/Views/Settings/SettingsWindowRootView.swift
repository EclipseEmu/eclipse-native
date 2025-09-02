#if os(macOS)
import SwiftUI

enum SettingsDestination: Hashable {
    case general
    case emulation
    case keyboard
    case controllers
    case core(Core)
}

private struct SettingsNavigationRoot<Content: View>: View {
    @StateObject private var navigationManager: NavigationManager = .init()
    private let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            content().navigationDestination(for: Destination.self, destination: Destination.navigationDestination)
        }
        .environmentObject(navigationManager)
    }
}

struct SettingsWindowRootView: View {
    @State private var destination: SettingsDestination = .general
    
    var body: some View {
        NavigationSplitView {
            List(selection: $destination) {
                Section {
                    Label("GENERAL", systemImage: "gear").tag(SettingsDestination.general)
                    Label("EMULATION", systemImage: "memorychip").tag(SettingsDestination.emulation)
                }
                Section("CONTROLS") {
                    Label("KEYBOARD", systemImage: "keyboard").tag(SettingsDestination.keyboard)
                    Label("CONTROLLERS", systemImage: "gamecontroller").tag(SettingsDestination.controllers)
                }
                Section("CORES") {
                    ForEach(Core.allCases) { core in
                        let coreType = core.type
                        Label(coreType.name, systemImage: "memorychip").tag(SettingsDestination.core(core))
                    }
                }
                .tint(Color.gray)
            }
            .navigationSplitViewColumnWidth(230)
        } detail: {
            detail
                .formStyle(.grouped)
                .navigationSplitViewColumnWidth(ideal: 600)
        }
    }
    
    @ViewBuilder
    var detail: some View {
        switch destination {
        case .general:
            SettingsNavigationRoot {
                Form {
                    SettingsGeneralContentView()
                }
                .navigationTitle("GENERAL")
            }
        case .emulation:
            Form {
                SettingsEmulationContentView()
            }
            .navigationTitle("EMULATION")
        case .keyboard:
            SettingsNavigationRoot(content: KeyboardProfilesView.init)
        case .controllers:
            SettingsNavigationRoot(content: ControllerProfilesView.init)
        case .core(let core):
            core.settingsView
        }
    }
}

@available(macOS 15.0, *)
#Preview(traits: .previewStorage) {
    SettingsWindowRootView()
        .environmentObject(Settings())
        .environmentObject(CoreRegistry())
        .environmentObject(ConnectedControllers())
}
#endif
