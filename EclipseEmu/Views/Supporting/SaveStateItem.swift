import CoreData
import SwiftUI

struct SaveStateItem: View {
    enum Action: Sendable {
        case startWithState(Persistence.Object<Game>, (PlayGameAction.Failure, Persistence.Object<Game>) -> Void)
        case loadState(EmulationViewModel)
    }

    @Environment(\.persistence) var persistence: Persistence
    @Environment(\.playGame) var playGame: PlayGameAction
    @Environment(\.dismiss) var dismiss: DismissAction

    @ObservedObject var saveState: SaveState
    @Binding var renameDialogTarget: SaveState?
    let action: Self.Action

    init(saveState: SaveState, action: Self.Action, renameDialogTarget: Binding<SaveState?>) {
        self.saveState = saveState
        self.action = action
        self._renameDialogTarget = renameDialogTarget
    }

    var body: some View {
        Button {
            Task {
                await onSelected()
            }
        } label: {
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
                try await persistence.delete(.init(object: saveState))
            } catch {
                print("[error] failed to delete save state:", error)
            }
        }
    }

    func onSelected() async {
        switch action {
        case .loadState(let model):
            guard case .loaded(let core) = model.state else { return }
            // FIXME: handle error
            guard let url = saveState.file.path(in: Files.shared) else { return }
            _ = await core.loadState(for: url)
            await MainActor.run {
                dismiss()
            }
        case .startWithState(let game, let onError):
            do {
                let game = try game.unwrap(in: persistence.viewContext)
                try await playGame(game: game, saveState: saveState, persistence: persistence)
                await MainActor.run {
                    dismiss()
                }
            } catch let error as PlayGameAction.Failure {
                onError(error, game)
            } catch {
                onError(.unknown(error), game)
            }
        }
    }
}
