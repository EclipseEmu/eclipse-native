import SwiftUI
import EclipseKit

private typealias OptionalCoreInfo = Optional<Core>

struct SystemSettingItemView: View {
    private let system: System
    @State private var selection: Core?
    private var coreRegistry: CoreRegistry
    private let cores: [Core]

    init(coreRegistry: CoreRegistry, system: System) {
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        self.coreRegistry = coreRegistry
    }

    var body: some View {
        CorePickerView(
            verbatim: system.string,
            selection: $selection,
            system: system,
            coreRegistry: coreRegistry
        )
        .onChange(of: selection, perform: update)
        .onAppear {
            selection = coreRegistry.get(for: system)
        }
    }

    func update(_ core: Core?) {
        coreRegistry.set(selection, for: system)
    }
}
