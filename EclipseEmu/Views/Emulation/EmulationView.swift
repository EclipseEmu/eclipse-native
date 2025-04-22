import SwiftUI
import EclipseKit

#if os(macOS)
struct EmulationMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 32.0, height: 32.0)
            .buttonStyle(.borderless)
            .controlSize(.large)
            .labelStyle(.iconOnly)
    }
}
#endif

struct EmulationView: View {
    @EnvironmentObject private var persistence: Persistence
    @EnvironmentObject private var playback: GamePlayback
    @EnvironmentObject private var settings: Settings
    @Environment(\.verticalSizeClass) private var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.scenePhase) private var scenePhase: ScenePhase

    @ObservedObject private var viewModel: EmulationViewModel
    @FocusState private var focusState

#if os(iOS)
    @State private var menuButtonLayout = TouchLayout.ElementDisplay(
        xOrigin: .leading,
        yOrigin: .trailing,
        x: 16,
        y: 0,
        width: 42,
        height: 42,
        hidden: false
    )
#else
    @State private var playbackBarIsVisible: Bool = true
    @State private var playbackBarHideTask: Task<Void, Never>?
    @State private var playbackBarHideTaskInstant: ContinuousClock.Instant = .now
#endif

    init(viewModel: EmulationViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            GameScreenView(model: viewModel)
                .aspectRatio(viewModel.aspectRatio, contentMode: .fit)
#if os(iOS)
                .padding(.bottom, self.verticalSizeClass == .compact ? 0 : 240)
                .ignoresSafeArea(.all)
#endif
                .navigationTitle(viewModel.game.name ?? "GAME_UNNAMED")
#if os(iOS)
            TouchControlsView(viewModel.core.inputs.handleTouchInput)
                .opacity(settings.touchControlsOpacity)
#endif
            playbackMenu
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.black)
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
        .onAppear {
            self.focusState = true
        }
        .onChange(of: scenePhase, perform: scenePhaseChanged)
        .onChange(of: viewModel.isSaveStateViewShown, perform: saveStateViewToggled)
        .onReceive(NotificationCenter.default.publisher(for: .EKGameCoreDidSave), perform: gameSaved)
        .sheet(isPresented: $viewModel.isSaveStateViewShown) {
            LoadStateView(game: viewModel.game, action: saveStateSelected)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("QUIT_GAME_TITLE", isPresented: $viewModel.isQuitConfirmationShown) {
            Button("QUIT", role: .destructive, action: quit)
        } message: {
            Text("QUIT_GAME_MESSAGE")
        }
    }

    @ViewBuilder
    var playbackMenu: some View {
#if !os(macOS)
        GeometryReader { proxy in
            let halfWidth = menuButtonLayout.width / 2
            let halfHeight = menuButtonLayout.height / 2
            let menuButtonX = menuButtonLayout.xOrigin == .leading
            ? menuButtonLayout.x + halfWidth
            : proxy.size.width - menuButtonLayout.x - halfWidth
            let menuButtonY = menuButtonLayout.yOrigin == .leading
            ? menuButtonLayout.y + halfHeight
            : proxy.size.height - menuButtonLayout.y - halfHeight

            Menu {
                menuContent
            } label: {
                Label("MENU", systemImage: "line.horizontal.3")
                    .frame(width: menuButtonLayout.width, height: menuButtonLayout.height)
                    .labelStyle(.iconOnly)
                    .background(Circle().strokeBorder(.white, lineWidth: 2).background(Circle().fill(Color.black)))
                    .foregroundStyle(.white)
                    .opacity(settings.touchControlsOpacity)
            }
            .menuOrder(.fixed)
            .position(.init(x: menuButtonX, y: menuButtonY))
        }
#else
        VStack {
            Spacer()
            HStack {
                menuContent
            }
            .frame(maxWidth: 400.0)
            .padding(.horizontal)
            .padding(.vertical, 8.0)
            .background(Material.ultraThick)
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .padding()
            .opacity(playbackBarIsVisible ? 1.0 : 0.0)
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .onContinuousHover(coordinateSpace: .global, perform: handleHoverPhase)
        .onDisappear {
            self.playbackBarHideTask?.cancel()
        }
#endif
    }

    @ViewBuilder
    var menuContent: some View {
        Button(action: togglePlayPause) {
            Label("TOGGLE_PLAY_PAUSE", systemImage: "playpause.fill")
        }
#if os(macOS)
        .buttonStyle(EmulationMenuButtonStyle())
#endif

#if os(macOS)
        Button(action: toggleFastForward) {
            Label("FAST_FORWARD", systemImage: "forward.fill")
        }
        .buttonStyle(EmulationMenuButtonStyle())
        .foregroundStyle(viewModel.isFastForwarding ? .primary : .secondary)
#else
        Toggle(isOn: $viewModel.isFastForwarding) {
            Label("FAST_FORWARD", systemImage: "forward.fill")
        }
#endif

#if os(macOS)
        Spacer()
#else
        Divider()
#endif

        Button(action: viewModel.saveState) {
            Label("SAVE_STATE", systemImage: "square.and.arrow.up.on.square")
        }
#if os(macOS)
        .buttonStyle(EmulationMenuButtonStyle())
#endif

        Button(action: showSaveStates) {
            Label("LOAD_SAVE_STATE", systemImage: "square.and.arrow.down.on.square")
        }
#if os(macOS)
        .buttonStyle(EmulationMenuButtonStyle())
#endif
#if os(macOS)
        Spacer()
#else
        Divider()
#endif

        Slider(value: $viewModel.volume, in: 0 ... 1) {} minimumValueLabel: {
            Label("VOLUME_DOWN", systemImage: "speaker.fill")
        } maximumValueLabel: {
            Label("VOLUME_UP", systemImage: "speaker.wave.3.fill")
        }
#if os(macOS)
        .labelStyle(.iconOnly)
        .controlSize(.small)
        .frame(maxWidth: 140)
#endif

        Button(role: .destructive, action: confirmQuit) {
            Label("QUIT", systemImage: "power")
        }
#if os(macOS)
        .labelStyle(.iconOnly)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .modify {
            if #available(macOS 14.0, *) {
                $0.buttonBorderShape(.circle)
            } else {
                $0
            }
        }
#endif
    }

    // MARK: Emulation Playback helpers

    private func togglePlayPause() {
        Task {
            await viewModel.togglePlayPause()
        }
    }

    private func toggleFastForward() {
        viewModel.isFastForwarding.toggle()
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

    private func gameSaved(_: Notification) {
        // FIXME: Show some visual indication
        print("game saved")
    }

    private func confirmQuit() {
        viewModel.isQuitConfirmationShown = true
    }

    private func quit() {
        Task {
            await viewModel.quit(playback: playback)
        }
    }

    // MARK: Save State helpers

    private func showSaveStates() {
        viewModel.isSaveStateViewShown = true
    }

    private func saveStateViewToggled(_ newState: Bool) {
        Task {
            if newState {
                await viewModel.core.pause(reason: .pendingUserInput)
            } else {
                await viewModel.core.play(reason: .pendingUserInput)
            }
        }
    }

    private func saveStateSelected(_ saveState: SaveStateObject) async -> Bool {
        let url = persistence.files.url(for: saveState.path)
        return await viewModel.core.loadState(for: url)
    }

    // MARK: macOS Playback Bar helpers

#if os(macOS)
    private func handleHoverPhase(hoverPhase: HoverPhase) {
        withAnimation {
            switch hoverPhase {
            case .ended:
                playbackBarIsVisible = false
            case .active:
                playbackBarIsVisible = true
                playbackBarHideTaskInstant = .now + .seconds(5)

                guard playbackBarHideTask == nil else { return }
                playbackBarHideTask = Task.detached(priority: .low) {
                    while await playbackBarHideTaskInstant > .now, !Task.isCancelled {
                        try? await Task.sleep(until: playbackBarHideTaskInstant)
                    }
                    await MainActor.run {
                        withAnimation {
                            playbackBarIsVisible = false
                            playbackBarHideTask = nil

                            NSCursor.setHiddenUntilMouseMoves(true)
                        }
                    }
                }
            }
        }
    }
#endif
}
