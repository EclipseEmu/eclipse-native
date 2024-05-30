import SwiftUI
import GameController

extension GCController: Identifiable {}

struct SettingsControlsView: View {
    @Environment(\.refresh) var refreshAction
    @State var controllers = GCController.controllers()

    var body: some View {
        List {
            Section("Built-in") {
                #if os(iOS)
                NavigationLink {
                    SettingsTouchLayoutView()
                } label: {
                    Label("Touch Controls", systemImage: "hand.draw")
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
                ForEach(controllers) { controller in
                    if controller.extendedGamepad != nil {
                        NavigationLink(destination: SettingsGamepadView(controller: controller)) {
                            Label(controller.vendorName ?? "Unknown Controller", systemImage: controllerSymbol(controller: controller))
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
