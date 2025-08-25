import SwiftUI
import EclipseKit

private typealias OptionalCoreInfo = Optional<Core>

struct CorePickerView<Label: View>: View {
    @EnvironmentObject private var coreRegistry: CoreRegistry

    private let label: () -> Label
    private let system: System
    private let cores: [Core]

    @Binding private var selectedCore: Core?

    init(
        @ViewBuilder label: @escaping () -> Label,
        selection: Binding<Core?>,
        system: System,
        coreRegistry: CoreRegistry
    ) {
        self.label = label
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        self._selectedCore = selection
    }

    var body: some View {
        Picker(selection: $selectedCore) {
            Text("NONE").tag(Optional<Core>.none)
            Divider().hidden(if: cores.isEmpty)
            ForEach(cores, id: \.rawValue) { core in
                Text(core.type.name).tag(Optional<Core>.some(core))
            }
        } label: {
            label()
        }
    }
}

extension CorePickerView where Label == Text {
    init(
        verbatim content: String,
        selection: Binding<Core?>,
        system: System,
        coreRegistry: CoreRegistry
    ) {
        self.label = { Text(verbatim: content) }
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        self._selectedCore = selection
    }
    
    init(
        _ titleKey: LocalizedStringKey,
        selection: Binding<Core?>,
        system: System,
        coreRegistry: CoreRegistry
    ) {
        self.label = { Text(titleKey) }
        self.system = system
        self.cores = coreRegistry.cores(for: system)
        self._selectedCore = selection
    }
}
