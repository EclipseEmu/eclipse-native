import SwiftUI

private struct LibraryViewWrapper: View {
	var body: some View {
		LibraryView()
	}
}

struct RootView: View {
	@EnvironmentObject private var persistence: Persistence
	@EnvironmentObject private var coreRegistry: CoreRegistry
    @EnvironmentObject private var playback: GamePlayback
    
	@StateObject private var navigationManager = NavigationManager()

	var body: some View {
        content.environmentObject(navigationManager)
	}
    
    // FIXME: on iOS 26, quitting out of a game messes up the layout.
    @ViewBuilder
    var content: some View {
        switch playback.playbackState {
        case .playing(let playbackData):
            playbackData.coreID.emulationView(with: playbackData)
        case .none:
            NavigationStack(path: $navigationManager.path) {
                LibraryViewWrapper()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .navigationDestination(for: Destination.self, destination: Destination.navigationDestination)
            }
        }
    }
}
