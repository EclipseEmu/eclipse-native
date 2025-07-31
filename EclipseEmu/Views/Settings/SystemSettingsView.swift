import SwiftUI
import EclipseKit

private typealias OptionalCoreInfo = Optional<Core>

struct SystemSettingItemView: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry

    private let system: System
    private let cores: [Core]

    @State private var selectedCore: Core?

    init(coreRegistry: CoreRegistry, system: System) {
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        // NOTE: setting self.selectedCore directly was not actually setting it.
        self._selectedCore = State(initialValue: coreRegistry.get(for: system))
    }

    var body: some View {
        Picker(system.string, selection: $selectedCore) {
            Text("NONE").tag(Optional<Core>.none)
            Divider().hidden(if: cores.isEmpty)
			ForEach(cores, id: \.rawValue) { core in
				Text(core.type.name).tag(Optional<Core>.some(core))
            }
        }
        .onChange(of: selectedCore, perform: update)
    }

    func update(_ core: Core?) {
        coreRegistry.set(selectedCore, for: system)
    }
}
