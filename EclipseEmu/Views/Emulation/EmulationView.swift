import EclipseKit
import SwiftUI

extension EmulationSpeed: View {
	var body: Text {
		return switch self {
        case .x0_50: Text(verbatim: "0.5x")
		case .x0_75: Text(verbatim: "0.75x")
		case .x1_00: Text(verbatim: "1x")
		case .x1_25: Text(verbatim: "1.25x")
		case .x1_50: Text(verbatim: "1.5x")
		case .x1_75: Text(verbatim: "1.75x")
		case .x2_00: Text(verbatim: "2x")
		}
	}
}

struct EmulationView<Core: CoreProtocol>: View {
    @ObservedObject private var viewModel: EmulationViewModel<Core>
    @Environment(\.scenePhase) private var scenePhase: ScenePhase

	@State private var screenOffset: CGSize = .zero
    @State private var menuOffset: CGRect = .zero
    @State private var isQuitConfirmationOpen: Bool = false
	@FocusState private var focusState
    
    init(viewModel: EmulationViewModel<Core>) {
        self.viewModel = viewModel
    }

	var body: some View {
		ZStack {
            GameScreenView(coordinator: viewModel.coordinator)
                .aspectRatio(viewModel.coordinator.screen.width / viewModel.coordinator.screen.height, contentMode: .fit)
                .overlay(alignment: .topLeading) {
                    if let message = viewModel.message {
                        Text(message)
                            .font(.caption2)
                            .padding(.horizontal, 6.0)
                            .padding(.vertical, 4.0)
                            .glassyBackground(.capsule)
                            .padding()
                    }
                }
				.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
				.ignoresSafeArea(.all, edges: .bottom)
                .offset(screenOffset)
#if !os(macOS)
			TouchControlsView(
                mappings: viewModel.touchMappings,
                coordinator: viewModel.coordinator.inputs,
                namingConvention: viewModel.coordinator.system.controlNamingConvention
			) { newScreenOffset in
				Task { @MainActor in
					screenOffset = .init(width: CGFloat(newScreenOffset.x), height: CGFloat(newScreenOffset.y))
				}
            } menuButtonPlacementChanged: { rect in
                Task { @MainActor in
                    menuOffset = rect
                }
            }
			.padding(.horizontal)
#endif
            EmulationMenuView(viewModel: viewModel, menuButtonOffset: $menuOffset)
                .padding(.horizontal)
		}
		.background(Color.black)
		.background(ignoresSafeAreaEdges: .all)
		.persistentSystemOverlays(.hidden)
        .onChange(of: scenePhase, perform: scenePhaseChanged)
        .onReceive(NotificationCenter.default.publisher(for: .EKGameCoreDidSave), perform: viewModel.gameSaved)
        .sheet(isPresented: $viewModel.isLoadStateViewOpen) {
            FormSheetView {
                LoadStateView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
        .makeFocusable()
        .disableKeyboardFeedbackSound()
        .focused($focusState)
#if os(macOS)
        .onContinuousHover(coordinateSpace: .global, perform: handleHoverPhase)
#endif
	}
    
    private func scenePhaseChanged(_ newPhase: ScenePhase) {
        Task {
            switch newPhase {
            case .active:
                await viewModel.sceneMadeActive()
            default:
                await viewModel.sceneHidden()
            }
        }
    }
}

#if os(macOS)
extension EmulationView {
    private func handleHoverPhase(hoverPhase: HoverPhase) {
        withAnimation {
            guard case .active = hoverPhase else {
                viewModel.menuBarIsVisible = false
                return
            }
            
            viewModel.menuBarIsVisible = true
            viewModel.menuBarHideTaskInstant = .now + .seconds(5)
            
            guard viewModel.menuBarHideTask == nil else { return }
            viewModel.menuBarHideTask = Task.detached(priority: .low) {
                while await viewModel.menuBarHideTaskInstant > .now, !Task.isCancelled {
                    try? await Task.sleep(until: viewModel.menuBarHideTaskInstant)
                }
                await MainActor.run {
                    withAnimation {
                        viewModel.menuBarIsVisible = false
                        viewModel.menuBarHideTask = nil
                        
                        NSCursor.setHiddenUntilMouseMoves(true)
                    }
                }
            }
        }
    }
}
#endif

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, persistence in
        EmulationLoaderView<TestCore>(data: .init(
            coreID: Core.testCore,
            system: .gba,
            game: game,
            saveState: nil,
            romPath: game.romPath,
            savePath: game.savePath,
            cheats: []
        ))
    }
    .environmentObject(Settings())
    .environmentObject(GamePlayback())
}
