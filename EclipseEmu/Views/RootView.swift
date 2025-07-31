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

	var body: some View {
		switch playback.playbackState {
		case .playing(let playbackData):
			playbackData.coreID.emulationView(with: playbackData)
				.environmentObject(navigationManager)
				.environmentObject(playback)
		case .none:
			NavigationStack(path: $navigationManager.path) {
				LibraryViewWrapper()
					.navigationDestination(for: Destination.self) { destination in
						destination.navigationDestination(destination, coreRegistry: coreRegistry)
					}
			}
			.environmentObject(navigationManager)
			.environmentObject(playback)
		}
	}
}
