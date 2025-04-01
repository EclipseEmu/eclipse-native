import SwiftUI
import EclipseKit

struct SystemSettingsView: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry

    private let system: GameSystem
    private let cores: [CoreInfo]

    @State private var selectedCore: CoreInfo?

    init(coreRegistry: CoreRegistry, system: GameSystem) {
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        if let selectedCore = coreRegistry.get(for: system) {
            self.selectedCore = selectedCore
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Core", selection: $selectedCore) {
                    ForEach(cores, id: \.id) { core in
                        Text(core.name).tag(core)
                    }
                }

                if let selectedCore {
                    NavigationLink(to: .coreSettings(selectedCore)) {
                        Label("Core Settings", systemImage: "gear")
                    }
                } else {
                    NavigationLink(to: .settings) {
                        Label("Core Settings", systemImage: "gear")
                    }
                    .disabled(true)
                }
            } header: {
                Text("Core")
            }
        }
        .navigationTitle(system.string)
    }
}

