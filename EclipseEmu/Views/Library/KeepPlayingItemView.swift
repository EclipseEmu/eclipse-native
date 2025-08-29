import SwiftUI
import CoreData

struct KeepPlayingItemView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var coreRegistry: CoreRegistry

    @ObservedObject var saveState: SaveStateObject
    @ObservedObject var viewModel: LibraryViewModel
    @State private var error: GameViewError?

    var body: some View {
        SaveStateItem(saveState, title: .game, action: self.action)
            .frame(height: 226.0)
            .gameErrorHandler(game: saveState.game, error: $error, fileImportRequest: $viewModel.fileImportRequest)
    }

    private func action(_ saveState: SaveStateObject) {
        Task { @MainActor in
            do {
                try await playback.play(state: saveState, persistence: persistence, coreRegistry: coreRegistry)
            } catch {
                print(error)
                self.error = .playbackError(error as! GamePlaybackError)
            }
        }
    }
}
