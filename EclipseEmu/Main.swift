import SwiftUI
import EclipseKit
import GameController

@main
struct EclipseEmuApp: App {
    @StateObject private var persistence = Persistence.shared
    @StateObject private var settings = Settings()
    @StateObject private var coreRegistry = CoreRegistry()
    @StateObject private var connectedControllers = ConnectedControllers()

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
                .environmentObject(connectedControllers)
                .onAppear {
                    settings.persistenceReady(persistence)
                }
            
		}
#elseif os(macOS)
		// NOTE: multiple windows can be supported, but controls will need to be reworked a little.
		Window("LIBRARY", id: "eclipse") {
			RootView()
				.persistence(persistence)
				.environmentObject(coreRegistry)
				.environmentObject(settings)
                .environmentObject(connectedControllers)
                .onAppear {
                    settings.persistenceReady(persistence)
                }
        }
		.commands {
			CommandGroup(replacing: CommandGroupPlacement.appSettings) {
				Button("SETTINGS", systemImage: "gear") {
					openWindow(id: "settings")
				}
				.keyboardShortcut(",", modifiers: .command)
			}
		}

		Window("SETTINGS", id: "settings") {
            SettingsWindowRootView()
                .persistence(persistence)
                .environmentObject(coreRegistry)
                .environmentObject(settings)
                .environmentObject(connectedControllers)
        }
#endif
    }
}

