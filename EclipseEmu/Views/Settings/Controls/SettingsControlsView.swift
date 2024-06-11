import GameController
import SwiftUI

extension GCController: Identifiable {}

struct SettingsControlsView: View {
    @Environment(\.refresh) var refreshAction
    @State var controllers = GCController.controllers()
    @State var isTouchEditorOpen = false

    var body: some View {
        List {
            Section("Built-in") {
                #if os(iOS)
                Button {
                    isTouchEditorOpen = true
                } label: {
                    Label("Touch Controls", systemImage: "hand.draw")
                }
                .fullScreenCover(isPresented: $isTouchEditorOpen) {
                    SettingsTouchLayoutView()
                }
                #endif
                if let keyboard = GCKeyboard.coalesced {
                    NavigationLink {
                        EmptyView()
                    } label: {
                        Label(keyboard.description, systemImage: "keyboard")
                    }
                }
            }

            Section("Connected Controllers") {
                ForEach(self.controllers) { controller in
                    if controller.extendedGamepad != nil {
                        NavigationLink(destination: SettingsGamepadView(controller: controller)) {
                            Label(
                                controller.vendorName ?? "Unknown Controller",
                                systemImage: self.controllerSymbol(controller: controller)
                            )
                        }
                    }
                }
            }
        }
        .onAppear {
            self.reloadControllers()
            GCController.startWirelessControllerDiscovery()
        }
        .onDisappear {
            GCController.stopWirelessControllerDiscovery()
        }
        .refreshable {
            self.reloadControllers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect)) { _ in
            self.reloadControllers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect)) { _ in
            self.reloadControllers()
        }
        .navigationTitle("Controls")
        .toolbar {
            ToolbarItem {
                Button {
                    self.reloadControllers()
                } label: {
                    Label("Refresh Controllers", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    func reloadControllers() {
        self.controllers = GCController.controllers()
    }

    func controllerSymbol(controller: GCController) -> String {
        return switch controller.productCategory {
        case GCProductCategoryXboxOne:
            "xbox.logo"
        case GCProductCategoryDualSense, GCProductCategoryDualShock4:
            "playstation.logo"
        default:
            "gamecontroller"
        }
    }
}

#Preview {
    SettingsControlsView()
}
