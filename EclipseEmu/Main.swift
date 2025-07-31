import SwiftUI
import EclipseKit
import GameController

@main
struct EclipseEmuApp: App {
    @StateObject private var persistence = Persistence.shared
    @StateObject private var settings = Settings()
    @StateObject private var coreRegistry = CoreRegistry()

#if os(macOS)
	@Environment(\.openWindow) var openWindow: OpenWindowAction
#endif

    var body: some Scene {
#if os(iOS)
		WindowGroup {
			RootView()
				.persistence(persistence)
				.environmentObject(coreRegistry)
				.environmentObject(settings)
                .onAppear {
                    settings.persistenceReady(persistence)
                }
		}
#elseif os(macOS)
		// NOTE: multiple windows can be supported, but controls will need to be reworked a little.
		Window("Eclipse", id: "eclipse") {
			RootView()
				.persistence(persistence)
				.environmentObject(coreRegistry)
				.environmentObject(settings)
        }
		.commands {
			CommandGroup(replacing: CommandGroupPlacement.appSettings) {
				Button {
					openWindow(id: "settings")
				} label: {
					Label("Settings", systemImage: "gear")
				}
				.keyboardShortcut(",", modifiers: .command)
			}
		}

		Window("Settings", id: "settings") {
            NavigationStack {
                SettingsView()
					.navigationDestination(for: Destination.self) { destination in
						destination.navigationDestination(destination, coreRegistry: coreRegistry)
					}
            }
            .persistence(persistence)
            .environmentObject(coreRegistry)
            .environmentObject(settings)
        }
#endif
    }
}
