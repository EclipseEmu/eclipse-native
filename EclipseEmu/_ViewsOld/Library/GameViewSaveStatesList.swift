import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct GameViewSaveStatesList: View {
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.playGame) private var playGame
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var game: Game
    @Binding var renameTarget: SaveState?
    let onPlayError: (PlayGameError, Game) -> Void

    @SectionedFetchRequest<Bool, SaveState>(sectionIdentifier: \.isAuto, sortDescriptors: [])
    private var saveStates

    init(game: Game, renameTarget: Binding<SaveState?>, onPlayError: @escaping (PlayGameError, Game) -> Void) {
        self.game = game
        self._renameTarget = renameTarget
        self.onPlayError = onPlayError

        let request = SaveState.fetchRequest()
        request.predicate = NSPredicate(format: "game == %@", game)
        request.includesSubentities = false
        request.fetchLimit = 10
        request.sortDescriptors = SaveStatesListView.sortDescriptors
        self._saveStates = SectionedFetchRequest(fetchRequest: request, sectionIdentifier: \.isAuto)
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(self.saveStates) { section in
                    ForEach(section) { saveState in
                        SaveStateItem(
                            saveState: saveState,
                            action: self.saveStateSelected,
                            renameDialogTarget: $renameTarget
                        )
                        .frame(minWidth: 140.0, idealWidth: 200.0, maxWidth: 260.0)
                    }
                    if section.id == saveStates.first?.id && saveStates.count > 1 {
                        Divider()
                    }
                }
            }
            .padding([.horizontal, .bottom])
        }
        .emptyState(saveStates.isEmpty) {
            EmptyMessage {
                Text("No Save States")
            } message: {
                Text("You haven't made any save states for this game. Use the \"Save State\" button in the emulation menu to create some.")
            }
        }
    }

    private func saveStateSelected(_ state: SaveState) {
        Task {
            do {
                try await playGame(
                    game: game,
                    saveState: state,
                    persistence: persistence
                )
                dismiss()
            } catch {
                onPlayError(error as! PlayGameError, game)
            }
        }
    }
}
