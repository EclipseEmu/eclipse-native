import SwiftUI

struct CheatItemView: View {
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var persistence: Persistence
    #if !os(macOS)
    @Environment(\.editMode) var editMode
    #endif
    @State var cheat: Cheat
    @Binding var editingCheat: Cheat?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(cheat.label ?? "Unnamed Cheat")
                    .lineLimit(1)
                Text(cheat.code ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            #if !os(macOS)
            if editMode?.wrappedValue == .active {
                Button {
                    self.editingCheat = cheat
                } label: {
                    Label("Edit", systemImage: "pencil.circle")
                        .labelStyle(.iconOnly)
                }
            } else {
                Toggle("Enabled", isOn: $cheat.enabled)
                    .labelsHidden()
            }
            #else
            Toggle("Enabled", isOn: $cheat.enabled)
                .labelsHidden()
            #endif
        }
        .onChange(of: cheat.enabled) { _ in
            try? persistence.mainContext.saveIfNeeded()
        }
        .contextMenu(ContextMenu(menuItems: {
            Button {
                self.editingCheat = cheat
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Task {
                    do {
                        try await persistence.objects.delete(.init(cheat))
                    } catch {
                        // FIXME: Surface error
                        print(error)
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }))
    }
}
