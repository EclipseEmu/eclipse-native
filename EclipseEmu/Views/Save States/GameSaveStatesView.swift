import SwiftUI

struct GameSaveStatesView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @ObservedObject var game: Game

    var body: some View {
        SaveStatesView(game: game, action: action)
            .navigationTitle("Save States")
    }

    private func action(_ saveState: SaveState) {
        Task {
            do {
                try await playback.play(state: saveState, persistence: persistence)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}
