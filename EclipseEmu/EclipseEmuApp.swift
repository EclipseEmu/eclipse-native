import SwiftUI
import mGBAEclipseCore

enum Destination: Hashable, Equatable {
    case settings
    case manageTags
    case editTag(Tag)

    case game(Game)
    case saveStates(Game)
}

extension NavigationLink where Label: View, Destination == Never {
    init(to value: EclipseEmu.Destination, @ViewBuilder label: () -> Label) {
        self = .init(value: value, label: label)
    }
}

@main
struct EclipseEmuApp: App {
    @StateObject private var persistence = Persistence(inMemory: true)
    @StateObject private var settings: Settings
    @StateObject private var playback: GamePlayback
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var coreRegistry: CoreRegistry

    init() {
        let settings = Settings()
        self._settings = StateObject(wrappedValue: settings)

        let coreRegistry = CoreRegistry(
            cores: [Box(mGBACoreInfo)],
            settings: settings
        )
        self._coreRegistry = StateObject(wrappedValue: coreRegistry)

        let playback = GamePlayback(coreRegistry: coreRegistry)
        self._playback = StateObject(wrappedValue: playback)
    }

    var body: some Scene {
        WindowGroup {
            switch playback.playbackState {
            case .playing(let data):
                EmulationView(
                    model: EmulationViewModel(
                        coreInfo: data.core,
                        game: try! data.game.get(in: persistence.mainContext),
                        saveState: data.saveState?.tryGet(in: persistence.mainContext),
                        emulationData: .init(
                            romPath: persistence.files.url(for: data.romPath),
                            savePath: persistence.files.url(for: data.savePath),
                            cheats: data.cheats as! [EmulationData.OwnedCheat]
                        ),
                        persistence: persistence
                    )
                )
                    .persistence(persistence)
                    .environmentObject(settings)
                    .environmentObject(navigationManager)
                    .environmentObject(playback)
            case .none:
                NavigationStack(path: $navigationManager.path) {
                    LibraryView2()
                        .navigationDestination(for: Destination.self) { destination in
                            switch destination {
                            case .settings:
                                EmptyView()
                            case .manageTags:
                                TagsView()
                            case .editTag(let tag):
                                TagDetailView(mode: .edit(tag))
                            case .game(let game):
                                GameView2(game: game)
                            case .saveStates(let game):
                                //                            SaveStatesView(game: game) { state in
                                //                                Task {
                                //                                    try await playback.play(state: state)
                                //                                }
                                //                            }
                                EmptyView()
                            }
                        }
                }
                .persistence(persistence)
                .environmentObject(settings)
                .environmentObject(navigationManager)
                .environmentObject(playback)
            }
        }
    }
}
