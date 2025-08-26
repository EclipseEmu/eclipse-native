import SwiftUI
import EclipseKit

struct SystemCorePickerView: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry
    private let system: System
    @State private var selection: Core?
    @State private var cores: [Core] = []

    init(_ system: System) {
        self.system = system
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
            cores = coreRegistry.cores(for: system)
            selection = coreRegistry.get(for: system)
        }
    }

    private func update(_ core: Core?) {
        coreRegistry.set(selection, for: system)
    }
}
