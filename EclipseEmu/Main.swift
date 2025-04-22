import SwiftUI
import EclipseKit
import mGBAEclipseCore
import GameController

enum Destination: Hashable, Equatable {
    case settings
    case systemSettings(GameSystem)
    case coreSettings(CoreInfo)
    case credits
    case licenses

    case keyboardProfiles
    case controllerProfiles
    case touchProfiles

    case controllerProfileEditor(ControllerProfileEditorTarget)
    case controllerSettings(GCController)

    case manageTags
    case editTag(TagObject)

    case game(GameObject)
    case saveStates(GameObject)
    case cheats(GameObject)
}

extension NavigationLink where Label: View, Destination == Never {
    init(to value: Eclipse.Destination, @ViewBuilder label: () -> Label) {
        self = .init(value: value, label: label)
    }
}

private struct LibraryViewWrapper: View {
    var body: some View {
        LibraryView()
    }
}

@main
struct EclipseEmuApp: App {
    @StateObject private var persistence = Persistence.shared
    @StateObject private var settings: Settings
    @StateObject private var playback: GamePlayback
    @StateObject private var navigationManager = NavigationManager()
    @StateObject private var coreRegistry: CoreRegistry

    init() {
        let settings = Settings()
        self._settings = StateObject(wrappedValue: settings)

        let coreRegistry = CoreRegistry(cores: [mGBACoreInfo], settings: settings)
        self._coreRegistry = StateObject(wrappedValue: coreRegistry)

        let playback = GamePlayback(coreRegistry: coreRegistry)
        self._playback = StateObject(wrappedValue: playback)
    }

    var body: some Scene {
        WindowGroup {
            switch playback.playbackState {
            case .playing(let viewModel):
                EmulationView(viewModel: viewModel)
                    .persistence(persistence)
                    .environmentObject(settings)
                    .environmentObject(navigationManager)
                    .environmentObject(playback)
            case .none:
                NavigationStack(path: $navigationManager.path) {
                    LibraryViewWrapper()
                        .navigationDestination(for: Destination.self, destination: navigationDestination)
                }
                .persistence(persistence)
                .environmentObject(coreRegistry)
                .environmentObject(settings)
                .environmentObject(navigationManager)
                .environmentObject(playback)
            }
        }

#if os(macOS)
        SwiftUI.Settings {
            NavigationStack {
                SettingsView()
                    .navigationDestination(for: Destination.self, destination: navigationDestination)
            }
            .persistence(persistence)
            .environmentObject(coreRegistry)
            .environmentObject(settings)
            .environmentObject(navigationManager)
            .environmentObject(playback)
        }
#endif
    }

    @ViewBuilder
    private func navigationDestination(_ destination: Destination) -> some View {
        switch destination {
        case .settings:
            SettingsView()
        case .systemSettings(let system):
            SystemSettingsView(coreRegistry: coreRegistry, system: system)
        case .coreSettings(let core):
            CoreSettingsView(core: core)
        case .credits:
            CreditsView()
        case .licenses:
            LicensesView()
        case .manageTags:
            TagsView()
        case .editTag(let tag):
            TagDetailView(mode: .edit(tag))
        case .game(let game):
            GameView(game: game)
        case .saveStates(let game):
            GameSaveStatesView(game: game)
        case .cheats(let game):
            CheatsView(game: game, coreRegistry: coreRegistry)
        case .controllerProfiles:
            ControllerProfilesView()
        case .controllerProfileEditor(let target):
            ControllerProfileEditorView(for: target)
        case .keyboardProfiles:
            // FIXME: TODO
            EmptyView()
        case .touchProfiles:
            // FIXME: TODO
            EmptyView()
        case .controllerSettings(let controller):
            ControllerSettingsView(controller: controller)
        }
    }
}
