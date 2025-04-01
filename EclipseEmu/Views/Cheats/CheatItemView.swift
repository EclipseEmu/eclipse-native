import SwiftUI

struct CheatItemView: View {
    @EnvironmentObject var persistence: Persistence
    #if !os(macOS)
    @Environment(\.editMode) var editMode
    #endif

    @ObservedObject var cheat: Cheat
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
                Button(action: edit) {
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
        .contextMenu(ContextMenu(menuItems: {
            Button(action: edit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: delete) {
                Label("Delete", systemImage: "trash")
            }
        }))
        .onChange(of: cheat.enabled, perform: toggleCheat)
    }

    func toggleCheat(newValue: Bool) {
        Task {
            do {
                try await persistence.objects.setCheatStatus(cheat: .init(cheat), isEnabled: newValue)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }

    func edit() {
        self.editingCheat = cheat
    }

    func delete() {
        Task {
            do {
                try await persistence.objects.delete(.init(cheat))
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}
