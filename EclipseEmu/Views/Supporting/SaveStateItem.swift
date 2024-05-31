import SwiftUI

struct SaveStateItem: View {
    enum Action {
        case startWithState(Game)
        case loadState(EmulationViewModel)
    }

    @Environment(\.persistenceCoordinator) var persistence
    @Environment(\.playGame) var playGame
    @Environment(\.dismiss) var dismiss

    @ObservedObject var saveState: SaveState
    @Binding var renameDialogTarget: SaveState?
    let action: Self.Action

    init(saveState: SaveState, action: Self.Action, renameDialogTarget: Binding<SaveState?>) {
        self.saveState = saveState
        self.action = action
        self._renameDialogTarget = renameDialogTarget
    }

    var body: some View {
        Button(action: self.onSelected) {
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

    func onSelected() {
        switch self.action {
        case .loadState(let model):
            guard case .loaded(let core) = model.state else { return }
            Task.detached {
                let url = await self.saveState.path(in: persistence)
                _ = await core.loadState(for: url)
                await MainActor.run {
                    dismiss()
                }
            }
        case .startWithState(let game):
            Task.detached {
                do {
                    try await playGame(game: game, saveState: saveState, persistence: persistence)
                    await MainActor.run {
                        dismiss()
                    }
                } catch {
                    print("failed to launch game: \(error.localizedDescription)")
                }
            }
        }
    }
}
