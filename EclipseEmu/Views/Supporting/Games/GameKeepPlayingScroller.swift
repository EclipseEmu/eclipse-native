import SwiftUI

struct GameKeepPlayingScroller<SaveStates: RandomAccessCollection>: View where SaveStates.Element == SaveState {
    var saveStates: SaveStates
    @ObservedObject var viewModel: GameListViewModel
    let onPlayError: (PlayGameError, Game) -> Void

    @State private var renameDialogTarget: SaveState? = nil
    @Environment(\.playGame) private var playGame: PlayGameAction
    @EnvironmentObject private var persistence: Persistence

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 16.0) {
                ForEach(saveStates) { saveState in
                    SaveStateItem(saveState: saveState, action: action, renameDialogTarget: $renameDialogTarget)
                }
            }
            .padding([.horizontal, .bottom])
        }
    }

    func action(saveState: SaveState) {
        guard let game = saveState.game else { return }
        Task {
            do {
                try await playGame(game: game, saveState: saveState, persistence: persistence)
            } catch {
                onPlayError(.unknown(error), game)
            }
        }
    }
}
