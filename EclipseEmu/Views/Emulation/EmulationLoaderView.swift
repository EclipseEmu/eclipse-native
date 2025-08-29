import EclipseKit
import SwiftUI

struct EmulationLoaderView<Core: CoreProtocol>: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var settings: Settings
    
    private let data: GamePlaybackData
    
    init(data: GamePlaybackData) {
        self.data = data
    }
    
	var body: some View {
        Suspense(task: load, view: EmulationView.init)
	}

	func load() async throws -> EmulationViewModel<Core> {
		let bindingManager = ControlBindingsManager(
            persistence: persistence,
            settings: settings,
            game: data.game,
            system: data.system
        )
        
        #if canImport(UIKit)
        let touchMappings = bindingManager.load(for: InputSourceTouchDescriptor())
        #else
        let touchMappings: EmulationViewModel<Core>.TouchMappingsHandle = ()
        #endif
        
        let settings = await persistence.objects.loadCoreSettings(Core.self)
		let coordinator: CoreCoordinator<Core> = try await CoreCoordinator.init(
			coreID: data.coreID,
			system: data.system,
			settings: settings,
			bindings: bindingManager,
			reorder: { $0 }
		)

		let romPath = persistence.files.url(for: data.romPath)
		let savePath = persistence.files.url(for: data.savePath)
		let stopAccessingRomFile = romPath.startAccessingSecurityScopedResource()
		let stopAccessingSaveFile = savePath.startAccessingSecurityScopedResource()
		try await coordinator.start(romPath: romPath, savePath: savePath)
        
        await coordinator.setCheats(cheats: data.cheats.map { (cheat: $0, isEnabled: true) })
        
        if let saveState = data.saveState {
            let path = persistence.files.url(for: saveState.path)
            try? await coordinator.loadState(from: path)
        }
        
		return .init(
            game: data.game,
            persistence: persistence,
            settings: self.settings,
            coordinator: coordinator,
            playback: playback,
			touchMappings: touchMappings,
			stopAccessingRomFile: stopAccessingRomFile,
			stopAccessingSaveFile: stopAccessingSaveFile
		)
	}
}
