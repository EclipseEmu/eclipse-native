import SwiftUI

struct CheatItemView: View {
    @EnvironmentObject var persistence: Persistence
    #if !os(macOS)
    @Environment(\.editMode) var editMode
    #endif

    @ObservedObject var cheat: CheatObject
    @Binding var editorTarget: EditorTarget<CheatObject>?

    var body: some View {
        LabeledContent {
#if !os(macOS)
            if editMode?.wrappedValue == .active {
                Button("EDIT", systemImage: "pencil.circle", action: edit)
                    .labelStyle(.iconOnly)
            } else {
                Toggle("CHEAT_ENABLED", isOn: $cheat.enabled)
                    .labelsHidden()
            }
#else
            Toggle("CHEAT_ENABLED", isOn: $cheat.enabled)
                .labelsHidden()
#endif
        } label: {
            VStack(alignment: .leading) {
                Text(verbatim: cheat.label, fallback: "CHEAT_UNNAMED")
                    .lineLimit(1)
                Text(verbatim: cheat.code ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contextMenu {
            Button("EDIT", systemImage: "pencil", action: edit)
            Button("DELETE", systemImage: "trash", role: .destructive, action: delete)
        }
        .onChange(of: cheat.enabled, perform: toggleCheat)
    }
    
    func edit() {
        self.editorTarget = .edit(cheat)
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
