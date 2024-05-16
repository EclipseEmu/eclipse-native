import SwiftUI

struct SaveStateItem: View {
    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.dismiss) var dismiss

    var saveState: SaveState
    var action: (SaveState, DismissAction) -> Void
    @Binding var renameDialogTarget: SaveState?

    init(saveState: SaveState, action: @escaping (SaveState, DismissAction) -> Void, renameDialogTarget: Binding<SaveState?>) {
        self.saveState = saveState
        self.action = action
        self._renameDialogTarget = renameDialogTarget
    }
    
    var body: some View {
        Button {
            self.action(self.saveState, self.dismiss)
        } label: {
            VStack(alignment: .leading) {
                ImageAssetView(asset: self.saveState.preview, cornerRadius: 8.0)
                Text("\(self.saveState.isAuto ? "Automatic State" : saveState.name ?? "Unnamed State")")
                    .font(.subheadline)
                Text("\(saveState.date, format: .dateTime)")
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
                    Label("Rename", systemImage: "rectangle.and.pencil.and.ellipsis")
                }
            }
            Button(role: .destructive, action: self.deleteSaveState) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    func deleteSaveState() {
        SaveStateManager.delete(saveState, in: persistence)
        persistence.saveIfNeeded()
    }
}
