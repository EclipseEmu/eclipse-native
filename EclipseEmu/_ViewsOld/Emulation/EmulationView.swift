import AVFoundation
import EclipseKit
import MetalKit
import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct EmulationView: View {
    @EnvironmentObject private var playback: GamePlayback
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject private var model: EmulationViewModel
    @FocusState private var focusState

    init(model: EmulationViewModel) {
        self.model = model
    }

    var body: some View {
        ZStack {
            GameScreenView(model: self.model)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(self.model.aspectRatio, contentMode: .fit)
#if os(iOS)
                .padding(.bottom, self.verticalSizeClass == .compact ? 0 : 240)
#endif
                .onChange(of: self.scenePhase) { newPhase in
                    Task {
                        switch newPhase {
                        case .active:
                            await self.model.sceneMadeActive()
                        default:
                            await self.model.sceneHidden()
                        }
                    }
                }
                .focused(self.$focusState)
                .modify {
                    if #available(macOS 14.0, iOS 17.0, *) {
                        $0.focusable().focusEffectDisabled().onKeyPress { _ in
                            .handled
                        }
                    } else {
                        // FIXME: Figure out how to do the above but on older versions.
                        //  Really all its doing is disabling the "funk" sound.
                        $0
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .EKGameCoreDidSave), perform: { _ in
                    print("game saved")
                })

            switch self.model.state {
            case .loading:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                    Button(role: .cancel) {
                        Task {
                            self.model.startTask?.cancel()
                            await self.model.quit(playback: playback)
                        }
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
#if !os(macOS)
                    .buttonBorderShape(.capsule)
#endif
                }
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Material.regular, ignoresSafeAreaEdges: .all)
            case .quitting:
                EmptyView()
            case .error(let error):
                ContentUnavailableMessage {
                    Label("Something went wrong", systemImage: "exclamationmark.octagon.fill")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Close") {
                        Task {
                            await self.model.quit(playback: self.playback)
                        }
                    }
                    .buttonStyle(.borderedProminent)
#if !os(macOS)
                        .buttonBorderShape(.capsule)
#endif
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Material.regular, ignoresSafeAreaEdges: .all)
            case .loaded(let core):
#if os(iOS)
                TouchControlsView { newValue in
                    core.inputs.handleTouchInput(newState: newValue)
                }.opacity(0.6)
#endif
                EmulationMenuView(
                    model: self.model,
                    menuButtonLayout: .init(
                        xOrigin: .leading,
                        yOrigin: .trailing,
                        x: 16,
                        y: 0,
                        width: 42,
                        height: 42,
                        hidden: false
                    ),
                    buttonOpacity: 0.6
                )
                .onAppear {
                    self.focusState = true
                }
            }
        }
        .onChange(of: self.model.isSaveStateViewShown, perform: { newValue in
            guard case .loaded(let core) = self.model.state else { return }
            Task {
                if newValue {
                    await core.pause(reason: .pendingUserInput)
                } else {
                    await core.play(reason: .pendingUserInput)
                }
            }
        })
        .sheet(isPresented: self.$model.isSaveStateViewShown) {
            SaveStatesView(model: self.model)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Quit Game", isPresented: self.$model.isQuitConfirmationShown) {
            Button("Quit", role: .destructive) {
                Task {
                    await model.quit(playback: playback)
                }
            }
        } message: {
            Text("Any unsaved progress will be lost.")
        }
        .background(Color.black, ignoresSafeAreaEdges: .all)
        .persistentSystemOverlays(.hidden)
    }
}
