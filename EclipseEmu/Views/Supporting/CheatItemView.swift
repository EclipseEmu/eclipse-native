import SwiftUI

struct CheatItemView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.persistenceCoordinator) var persistence
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
        .onChange(of: cheat.enabled, perform: { newValue in
            try? viewContext.save()
        })
        .contextMenu(ContextMenu(menuItems: {
            Button {
                self.editingCheat = cheat
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                try? CheatManager.delete(cheat: cheat, in: persistence, save: true)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }))
    }
}
