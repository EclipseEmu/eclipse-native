import SwiftUI

#if canImport(UIKit)
struct EmulationMenuView: View {
    @ObservedObject var model: EmulationViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Button("Fast Foward") {
                    Task {
                        await model.coreCoordinator.setFastForward(enabled: model.coreCoordinator.rate != 2.0)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton(dismissAction: dismiss)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        model.isQuitDialogShown = true
                    } label: {
                        Label("Quit", systemImage: "xmark")
                            .labelStyle(.titleOnly)
                    }
                }
            }
        }
    }
}
#endif

// Rather than displaying the emulation menu options in a sheet, having them in a bar on Mac makes more sense.
#if os(macOS)
struct EmulationMenuViewBar: View {
    @ObservedObject var model: EmulationViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 8.0) {
                Button {
                    Task(priority: .userInitiated) {
                        if await model.coreCoordinator.isRunning {
                            await model.coreCoordinator.pause()
                        } else {
                            await model.coreCoordinator.play()
                        }
                    }
                } label: {
                    if model.coreCoordinator.isRunning {
                        Label("Pause", systemImage: "pause.fill")
                    } else {
                        Label("Play", systemImage: "play.fill")
                    }
                }
                .frame(width: 32.0, height: 32.0)
                .buttonStyle(.borderless)
                .controlSize(.large)
                .labelStyle(.iconOnly)
                .modify {
                    if #available(iOS 17.0, macOS 14.0, *) {
                        $0.transition(.symbolEffect)
                    } else {
                        $0
                    }
                }

                Button {
                    model.isRestartDialogShown = true
                } label: {
                    Label("Restart", systemImage: "arrow.clockwise")
                }
                .frame(width: 32.0, height: 32.0)
                .buttonStyle(.borderless)
                .controlSize(.large)
                .labelStyle(.iconOnly)

                Button {
                    print("Save State")
                } label: {
                    Label("Save State", systemImage: "tray.and.arrow.down")
                }
                .frame(width: 32.0, height: 32.0)
                .buttonStyle(.borderless)
                .controlSize(.large)
                .labelStyle(.iconOnly)
                Button {
                    print("Load State")
                } label: {
                    Label("Load State", systemImage: "tray.and.arrow.up")
                }
                .frame(width: 32.0, height: 32.0)
                .buttonStyle(.borderless)
                .controlSize(.large)
                .labelStyle(.iconOnly)

                Spacer(minLength: 16.0)

                Slider(value: $model.volume, in: 0...1) {} minimumValueLabel: {
                    Label("Lower Volume", systemImage: "speaker")
                } maximumValueLabel: {
                    Label("Raise Volume", systemImage: "speaker.wave.3")
                }.labelStyle(.iconOnly)
                    .controlSize(.small)

                Spacer(minLength: 16.0)
                
                Button {
                    self.model.isQuitDialogShown = true
                } label: {
                    Label("Quit Game", systemImage: "power")
                }
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
                .tint(.red)
            }
            .fontWeight(.semibold)
            .frame(minWidth: 0, maxWidth: 400.0)
            .padding(.horizontal)
            .padding(.vertical, 8.0)
            .background(Material.bar)
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
        }.padding()
    }
}
#endif
