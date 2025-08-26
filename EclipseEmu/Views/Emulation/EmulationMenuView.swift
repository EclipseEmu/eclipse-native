import SwiftUI
import EclipseKit

private extension View {
    @ViewBuilder
    func confirmationDialog(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        cancelLabel: LocalizedStringKey = "CANCEL",
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        self.confirmationDialog(title, isPresented: isPresented) {
            Button(cancelLabel, role: .cancel, action: {})
            Button(label, role: .destructive, action: action)
        } message: {
            Text(message)
        }
    }
}

struct EmulationMenuView<Core: CoreProtocol>: View {
    @ObservedObject var viewModel: EmulationViewModel<Core>
    @Binding var menuButtonOffset: CGRect
    let features: CoreFeatures
    
    @State private var isQuitConfirmationOpen: Bool = false
    @State private var isResetConfirmationOpen: Bool = false
    
    init(viewModel: EmulationViewModel<Core>, menuButtonOffset: Binding<CGRect>) {
        self.viewModel = viewModel
        self._menuButtonOffset = menuButtonOffset
        self.features = Core.features(for: viewModel.coordinator.system)
    }
    
#if os(macOS)
    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 16.0) {
                playPauseButton
                
                volumeSlider
                    .frame(maxWidth: 120)
                    .controlSize(.small)
                
                Spacer()
                
                Menu("SETTINGS", systemImage: "gearshape.fill") {
                    speedPicker
                        .labelStyle(.titleOnly)
                    Divider()
                    
                    if features.contains(.saveStates) {
                        saveStateButton
                            .labelStyle(.titleOnly)
                        loadStateButton
                            .labelStyle(.titleOnly)
                    }
                }
                
                HStack {
                    if features.contains(.softReset) {
                        resetButton
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .confirmationDialog(isPresented: $isResetConfirmationOpen, title: "RESET_GAME_TITLE", message: "RESET_GAME_MESSAGE", label: "RESET", action: reset)
                    }

                    quitButton
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .confirmationDialog(isPresented: $isQuitConfirmationOpen, title: "QUIT_GAME_TITLE", message: "QUIT_GAME_MESSAGE", label: "QUIT", action: quit)
                }
            }
            .menuIndicator(.hidden)
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .labelStyle(.iconOnly)
            .padding(.horizontal)
            .padding(.vertical, 8.0)
            .modify {
                if #available(macOS 26.0, *) {
                    $0.glassEffect(.regular.interactive())
                } else {
                    $0.background(Material.regular).clipShape(RoundedRectangle(cornerRadius: 12.0))
                }
            }
            .frame(maxWidth: 360)
            .compositingGroup()
            .opacity(viewModel.menuBarIsVisible ? 1.0 : 0.0)
        }
        .padding(.bottom)
        .onDisappear {
            viewModel.menuBarHideTask?.cancel()
        }
    }
#else
    var body: some View {
        Menu {
            playPauseButton
            Menu("AUDIO", systemImage: "speaker.2") {
                requireRingerToggle
                volumeSlider
            }
            
            speedPicker.pickerStyle(.menu)
            
            Divider()
            
            if features.contains(.saveStates) {
                saveStateButton
                loadStateButton
                
                Divider()
            }
            
            if features.contains(.softReset) {
                resetButton
            }
            quitButton
        } label: {
            Label("MENU", systemImage: "house.circle")
                .labelStyle(.iconOnly)
                .font(.system(size: menuButtonOffset.height * 0.625))
                .tint(Color.white)
        }
        .menuOrder(.fixed)
        .confirmationDialog(isPresented: $isResetConfirmationOpen, title: "RESET_GAME_TITLE", message: "RESET_GAME_MESSAGE", label: "RESET", action: reset)
        .confirmationDialog(isPresented: $isQuitConfirmationOpen, title: "QUIT_GAME_TITLE", message: "QUIT_GAME_MESSAGE", label: "QUIT", action: quit)
        .frame(width: menuButtonOffset.width, height: menuButtonOffset.height)
        .position(x: menuButtonOffset.midX, y: menuButtonOffset.midY)
    }
#endif

    @ViewBuilder
    var quitButton: some View {
        ToggleButton("QUIT", systemImage: "power", role: .destructive, value: $isQuitConfirmationOpen)
    }
    
    @ViewBuilder
    var resetButton: some View {
        ToggleButton("RESET_GAME", systemImage: "arrow.clockwise", role: .destructive, value: $isResetConfirmationOpen)
    }
    
    @ViewBuilder
    var playPauseButton: some View {
        let titleKey: LocalizedStringKey = viewModel.isPlaying ? "PAUSE" : "PLAY"
#if os(macOS)
        let systemImage : String = viewModel.isPlaying ? "pause.fill" : "play.fill"
#else
        let systemImage : String = viewModel.isPlaying ? "pause" : "play"
#endif

        ToggleButton(titleKey, systemImage: systemImage, value: $viewModel.isPlaying)
            .modify {
                if #available(iOS 17.0, *) {
                    $0.contentTransition(.symbolEffect)
                } else {
                    $0
                }
            }
    }
    
    @ViewBuilder
    var speedPicker: some View {
        Picker("SPEED", systemImage: "speedometer", selection: $viewModel.speed) {
            ForEach(EmulationSpeed.allCases, id: \.rawValue) { value in
                value.tag(value)
            }
        }
    }
    
    @ViewBuilder
    var volumeSlider: some View {
        Slider(value: $viewModel.volume) {
            #if os(iOS)
            Text("VOLUME \(viewModel.volume * 100, format: .number.precision(.fractionLength(0)))%")
            #endif
        } minimumValueLabel: {
            Label("VOLUME_DOWN", systemImage: "speaker.fill")
        } maximumValueLabel: {
            Label("VOLUME_UP", systemImage: "speaker.3.fill")
        }
        .labelStyle(.iconOnly)
    }
    
    #if os(iOS)
    @ViewBuilder
    var requireRingerToggle: some View {
        Toggle("IGNORE_SILENT_MODE", systemImage: "bell", isOn: $viewModel.ignoreSilentMode)
    }
    #endif
    
    @ViewBuilder
    var loadStateButton: some View {
        ToggleButton("LOAD_STATE", systemImage: "square.and.arrow.up", value: $viewModel.isLoadStateViewOpen)
    }
    
    @ViewBuilder
    var saveStateButton: some View {
        Button("SAVE_STATE", systemImage: "square.and.arrow.down") {
            Task {
                try await viewModel.saveState()
            }
        }
    }
    
    func quit() {
        Task {
            await viewModel.quit()
        }
    }

    func reset() {
        Task {
            await viewModel.coordinator.reset()
        }
    }
}
