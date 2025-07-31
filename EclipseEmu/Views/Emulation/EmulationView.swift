import EclipseKit
import SwiftUI

extension EmulationSpeed: View {
	var body: Text {
		return switch self {
		case .x0_50: Text("0.5x")
		case .x0_75: Text("0.75x")
		case .x1_00: Text("1x")
		case .x1_25: Text("1.25x")
		case .x1_50: Text("1.5x")
		case .x1_75: Text("1.75x")
		case .x2_00: Text("2x")
		}
	}
}

struct EmulationLoaderView<Core: CoreProtocol & SendableMetatype>: View {
	let data: GamePlaybackData
	@EnvironmentObject var persistence: Persistence

	struct EmulationViewLoadedData {
		let coordinator: CoreCoordinator<Core>
#if canImport(UIKit)
		let touchMappings: TouchMappings
#endif

		let stopAccessingRomFile: Bool
		let stopAccessingSaveFile: Bool
	}

	var body: some View {
		Suspense(task: load) { loadedData in
#if canImport(UIKit)
			EmulationView(coordinator: loadedData.coordinator, touchMappings: loadedData.touchMappings, data: data)
				.modify {
					if #available(iOS 18.0, *) {
						$0.toolbarVisibility(.hidden, for: .navigationBar)
					} else {
						$0
					}
				}
#else
			EmulationView(coordinator: loadedData.coordinator, data: data)
#endif
		}
	}

	func load() async throws -> EmulationViewLoadedData {
		let settings = Core.Settings()
		let inputCoordinator = ControlBindingsManager(persistence: persistence, game: data.game, system: data.system)
		let actor: CoreCoordinator<Core> = try await CoreCoordinator.init(
			coreID: data.coreID,
			system: data.system,
			settings: settings,
			bindings: inputCoordinator,
			reorder: { $0 }
		)

		let romPath = persistence.files.url(for: data.romPath)
		let savePath = persistence.files.url(for: data.savePath)
		let stopAccessingRomFile = romPath.startAccessingSecurityScopedResource()
		let stopAccessingSaveFile = savePath.startAccessingSecurityScopedResource()
		try await actor.start(romPath: romPath, savePath: savePath)

		#if canImport(UIKit)
		let touchMappings = inputCoordinator.load(for: InputSourceTouchDescriptor())
		return .init(
			coordinator: actor,
			touchMappings: touchMappings,
			stopAccessingRomFile: stopAccessingRomFile,
			stopAccessingSaveFile: stopAccessingSaveFile
		)
		#else
		return .init(
			coordinator: actor,
			stopAccessingRomFile: stopAccessingRomFile,
			stopAccessingSaveFile: stopAccessingSaveFile
		)
		#endif
	}
}

struct EmulationView<Core: CoreProtocol & SendableMetatype>: View {
	@EnvironmentObject var gamePlayback: GamePlayback
	let coordinator: CoreCoordinator<Core>
#if canImport(UIKit)
	let touchMappings: TouchMappings
#endif
	let data: GamePlaybackData

	@EnvironmentObject var persistence: Persistence

	@State private var isPlaying: Bool = true
	@State private var speed: EmulationSpeed = .x1_00
	@State private var screenOffset: CGSize = .zero
	@State private var isMenuOpen: Bool = false

	@FocusState private var focusState

	var body: some View {
		ZStack {
			GameScreenView(coordinator: coordinator)
				.aspectRatio(coordinator.screen.width / coordinator.screen.height, contentMode: .fit)
				.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
				.ignoresSafeArea(.all, edges: .bottom)
				.offset(screenOffset)
				.overlay(alignment: .bottom) {
#if os(macOS)
					emulationMenuBar
						.padding()
						.opacity(0.0)
#endif
				}
#if !os(macOS)
			TouchControlsView(
				mappings: touchMappings,
				coordinator: coordinator.inputs,
				namingConvention: coordinator.system.controlNamingConvention
			) { newScreenOffset in
				Task { @MainActor in
					self.screenOffset = .init(width: CGFloat(newScreenOffset.x), height: CGFloat(newScreenOffset.y))
				}
			} menuButtonAction: {
				isMenuOpen = true
			}
			.padding(.horizontal)
#endif
		}
		.background(Color.black)
		.background(ignoresSafeAreaEdges: .all)
		.sheet(isPresented: $isMenuOpen) {
			NavigationStack {
				EmulationMenuView(quit: self.quit)
			}
			.presentationDetents([.medium, .large])
		}
		.persistentSystemOverlays(.hidden)
		.focused($focusState)
		.modify {
			if #available(macOS 14.0, iOS 17.0, *) {
				$0.focusable().focusEffectDisabled().onKeyPress { _ in .handled }
			} else {
				// FIXME: Figure out how to disable the funk sound on older versions.
				$0
			}
		}
		.onDisappear {
			let romPath = persistence.files.url(for: data.romPath)
			let savePath = persistence.files.url(for: data.savePath)
			romPath.stopAccessingSecurityScopedResource()
			savePath.stopAccessingSecurityScopedResource()
		}
	}

	@ViewBuilder
	var emulationMenuBar: some View {
		HStack(spacing: 16.0) {
			Button(action: togglePlayPause) {
				if isPlaying {
					Label("Pause", systemImage: "pause.fill")
				} else {
					Label("Play", systemImage: "play.fill")
				}
			}

			Slider(value: .constant(0.6)) {} minimumValueLabel: {
				Label("Lower Volume", systemImage: "speaker.fill")
			} maximumValueLabel: {
				Label("Raise Volume", systemImage: "speaker.3.fill")
			}
			.frame(maxWidth: 120)
			.controlSize(.small)

			Spacer()

			Menu {
				Picker("Speed", selection: $speed) {
					ForEach(EmulationSpeed.allCases, id: \.rawValue) { speed in
						speed.tag(speed)
					}
				}
			} label: {
				Label("Settings", systemImage: "gearshape.fill")
			}
			Button(action: stop) {
				Label("Quit Game", systemImage: "power")
			}
			.buttonStyle(.borderedProminent)
			.tint(.red)
		}
		.menuIndicator(.hidden)
		.menuStyle(.button)
		.buttonStyle(.borderless)
		.labelStyle(.iconOnly)
		.padding(.horizontal)
		.padding(.vertical, 8.0)
		.background(Material.regular)
		.clipShape(RoundedRectangle(cornerRadius: 12.0))
		.frame(maxWidth: 320)
	}

	func togglePlayPause() {}

	func toggleFastForward() {
		print("toggle fast forward")
	}

	func quit() {
		Task {
			await coordinator.stop()
			gamePlayback.closeGame()
		}
	}

	func stop() {
		Task {
			await coordinator.stop()
		}
	}
}

