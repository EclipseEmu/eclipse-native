import SwiftUI

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

struct EmulationMenuView: View {
    @StateObject var model: EmulationViewModel
    var menuButtonLayout: TouchLayout.ElementDisplay
    var buttonOpacity: Double
    
    @Environment(\.playGame) var playGame
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
#if os(macOS)
    @State var isVisible = false
    @State var hideTask: Task<Void, Never>?
    @State var hideTaskInstant: ContinuousClock.Instant = .now
#endif
    
    var content: some View {
        Group {
            Button(action: self.togglePlayPause) {
                Label("Play/Pause", systemImage: "playpause.fill")
            }
#if os(macOS)
            .buttonStyle(EmulationMenuButtonStyle())
#endif
            
#if os(macOS)
            Button(action: self.toggleFastForward) {
                Label("Fast Forward", systemImage: "forward.fill")
            }
            .buttonStyle(EmulationMenuButtonStyle())
            
            .foregroundStyle(model.isFastForwarding ? .primary : .secondary)
#else
            Toggle(isOn: $model.isFastForwarding) {
                Label("Fast Forward", systemImage: "forward.fill")
            }
#endif
            #if os(macOS)
            Spacer()
            #else
            Divider()
            #endif
            
            Button(action: {
                model.saveState(isAuto: false)
            }) {
                Label("Save State", systemImage: "square.and.arrow.up.on.square")
            }
#if os(macOS)
            .buttonStyle(EmulationMenuButtonStyle())
#endif

            Button(action: self.showSaveStates) {
                Label("Load State", systemImage: "square.and.arrow.down.on.square")
            }
#if os(macOS)
            .buttonStyle(EmulationMenuButtonStyle())
#endif

#if os(macOS)
            Spacer()
#else
            Divider()
#endif
            
            Slider(value: $model.volume, in: 0...1) {} minimumValueLabel: {
                Label("Lower Volume", systemImage: "speaker.fill")
            } maximumValueLabel: {
                Label("Raise Volume", systemImage: "speaker.wave.3.fill")
            }
#if os(macOS)
            .labelStyle(.iconOnly)
            .controlSize(.small)
            .frame(maxWidth: 140)
#endif
            
            Button(role: .destructive, action: self.showQuitDialog) {
                Label("Quit", systemImage: "power")
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
    }
    
    var body: some View {
        GeometryReader { proxy in
            let halfWidth = menuButtonLayout.width / 2
            let halfHeight = menuButtonLayout.height / 2
            let menuButtonX = menuButtonLayout.xOrigin == .leading
            ? menuButtonLayout.x + halfWidth
            : proxy.size.width - menuButtonLayout.x - halfWidth
            let menuButtonY = menuButtonLayout.yOrigin == .leading
            ? menuButtonLayout.y + halfHeight
            : proxy.size.height - menuButtonLayout.y - halfHeight
            
#if !os(macOS)
            Menu {
                content
            } label: {
                Label("Menu", systemImage: "line.horizontal.3")
                    .frame(
                        width: menuButtonLayout.width,
                        height: menuButtonLayout.height
                    )
                    .labelStyle(.iconOnly)
                    .background(
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                            .background(Circle().fill(Color.black))
                    )
                    .foregroundStyle(.white)
                    .opacity(buttonOpacity)
            }
            .modify {
                if #available(iOS 16.0, *) {
                    $0.menuOrder(.fixed)
                } else {
                    $0
                }
            }
            .position(.init(x: menuButtonX, y: menuButtonY))
#else
            VStack {
                Spacer()
                HStack {
                    content
                }
                .frame(maxWidth: 400.0)
                .padding(.horizontal)
                .padding(.vertical, 8.0)
                .background(Material.ultraThick)
                .clipShape(RoundedRectangle(cornerRadius: 12.0))
                .padding()
                .opacity(self.isVisible ? 1.0 : 0.0)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .onContinuousHover(coordinateSpace: .global) { hoverPhase in
                withAnimation {
                    switch hoverPhase {
                    case .active(_):
                        self.isVisible = true
                        self.hideTaskInstant = .now + .seconds(5)
                        if self.hideTask == nil {
                            self.hideTask = Task.detached(priority: .low) {
                                while await self.hideTaskInstant > .now && !Task.isCancelled {
                                    try? await Task.sleep(until: self.hideTaskInstant)
                                }
                                await MainActor.run {
                                    withAnimation {
                                        self.isVisible = false
                                        self.hideTask = nil
                                        
                                        NSCursor.setHiddenUntilMouseMoves(true)
                                    }
                                }
                            }
                        }
                    case .ended:
                        self.isVisible = false
                    }
                }
            }
            .onDisappear {
                self.hideTask?.cancel()
            }
#endif
        }
    }
    
    func toggleFastForward() {
        model.isFastForwarding.toggle()
    }
    
    func togglePlayPause() {
        Task {
            await model.togglePlayPause()
        }
    }
    
    func showQuitDialog() {
        model.isQuitConfirmationShown = true
    }
    
    func showSaveStates() {
        model.isSaveStateViewShown = true
    }
}

#if DEBUG
#Preview {
    ZStack {
        EmulationMenuView(
            model: .init(
                coreInfo: .init(),
                game: .init(context: PersistenceCoordinator.preview.container.viewContext), 
                persistence: .preview,
                emulationData: .init(
                    romPath: URL(string: "/")!,
                    savePath: URL(string: "/")!,
                    cheats: .init()
                )
            ),
            menuButtonLayout: .init(
                xOrigin: .leading,
                yOrigin: .trailing,
                x: 16,
                y: 0,
                width: 50,
                height: 50,
                hidden: false
            ),
            buttonOpacity: 0.6
        )
    }
    .background(Color.red)
}
#endif
