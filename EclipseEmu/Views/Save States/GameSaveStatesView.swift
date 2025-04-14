import SwiftUI

struct GameSaveStatesView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @ObservedObject var game: GameObject

    var body: some View {
        SaveStatesView(game: game, action: action)
            .navigationTitle("Save States")
    }

    private func action(_ saveState: SaveStateObject) {
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
