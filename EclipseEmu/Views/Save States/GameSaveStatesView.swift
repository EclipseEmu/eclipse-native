import SwiftUI

struct GameSaveStatesView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
	@EnvironmentObject private var coreRegistry: CoreRegistry
    @ObservedObject var game: GameObject
    
    @State private var error: GameViewError?
    @State private var fileImportRequest: FileImportType?

    var body: some View {
        SaveStatesView(game: game, action: action)
            .gameErrorHandler(game: game, error: $error, fileImportRequest: $fileImportRequest)
            .navigationTitle("SAVE_STATES")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton("DONE", action: dismiss.callAsFunction)
                }
            }
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
