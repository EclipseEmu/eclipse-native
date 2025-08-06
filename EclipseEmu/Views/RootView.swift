import SwiftUI

private struct LibraryViewWrapper: View {
	var body: some View {
		LibraryView()
	}
}

struct RootView: View {
	@EnvironmentObject private var persistence: Persistence
	@EnvironmentObject private var coreRegistry: CoreRegistry
	@StateObject private var playback = GamePlayback()
	@StateObject private var navigationManager = NavigationManager()

    // FIXME: on iOS 26, quitting out of a game messes up the layout.
	var body: some View {
        Group {
            switch playback.playbackState {
            case .playing(let playbackData):
                playbackData.coreID.emulationView(with: playbackData)
            case .none:
                NavigationStack(path: $navigationManager.path) {
                    LibraryViewWrapper()
                        .navigationDestination(for: Destination.self) { destination in
                            destination.navigationDestination(destination, coreRegistry: coreRegistry)
                        }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
		}
        .environmentObject(navigationManager)
        .environmentObject(playback)
	}
}
