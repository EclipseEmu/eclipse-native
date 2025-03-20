import SwiftUI

struct SaveStateItem: View {
    @EnvironmentObject var persistence: Persistence
    @Environment(\.playGame) var playGame
    @Environment(\.dismiss) var dismiss

    @ObservedObject var saveState: SaveState
    @Binding var renameDialogTarget: SaveState?
    let onSelected: (SaveState) -> Void

    init(saveState: SaveState, action onSelected: @escaping (SaveState) -> Void, renameDialogTarget: Binding<SaveState?>) {
        self.saveState = saveState
        self.onSelected = onSelected
        self._renameDialogTarget = renameDialogTarget
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                ImageAssetView(asset: self.saveState.preview, cornerRadius: 8.0)
                Text("\(self.saveState.isAuto ? "Automatic State" : saveState.name ?? "Unnamed State")")
                    .font(.subheadline)
                Text("\(saveState.date ?? .now, format: .dateTime)")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !self.saveState.isAuto {
                Button {
                    self.renameDialogTarget = self.saveState
                } label: {
                    Label("Rename", systemImage: "character.cursor.ibeam")
                }
            }
            Button(role: .destructive, action: self.deleteSaveState) {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    func deleteSaveState() {
        Task {
            do {
                try await persistence.library.delete(.init(saveState))
            } catch {
                // FIXME: surface error
                print(error)
            }
        }
    }

    func action() {
        self.onSelected(self.saveState)
    }
}
