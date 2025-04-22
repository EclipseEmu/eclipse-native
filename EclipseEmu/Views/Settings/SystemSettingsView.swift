import SwiftUI
import EclipseKit

private typealias OptionalCoreInfo = Optional<CoreInfo>

struct SystemSettingsView: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry

    private let system: GameSystem
    private let cores: [CoreInfo]

    @State private var selectedCore: CoreInfo?

    init(coreRegistry: CoreRegistry, system: GameSystem) {
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        // NOTE: setting self.selectedCore directly was not actually setting it.
        self._selectedCore = State(initialValue: coreRegistry.get(for: system))
    }

    var body: some View {
        Form {
            Section {
                Picker("CORE", selection: $selectedCore) {
                    Text("NONE").tag(OptionalCoreInfo.none)
                    Divider().hidden(if: cores.isEmpty)
                    ForEach(cores, id: \.id) { core in
                        Text(core.name).tag(OptionalCoreInfo.some(core))
                    }
                }

                if let selectedCore {
                    NavigationLink(to: .coreSettings(selectedCore)) {
                        Label("CORE_SETTINGS", systemImage: "gear")
                    }
                }
            } header: {
                Text("CORE")
            }
        }
        .navigationTitle(system.string)
    }
}

