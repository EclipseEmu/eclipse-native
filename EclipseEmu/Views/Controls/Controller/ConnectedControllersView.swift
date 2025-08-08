import SwiftUI
import GameController

struct ConnectedControllersView: View {
    @State var connectedControllers: [GCController] = []

    var body: some View {
        Section("CONNECTED_CONTROLLERS") {
            if connectedControllers.isEmpty {
                EmptyMessage.listItem(title: "NO_CONNECTED_CONTROLLERS_TITLE", message: "NO_CONNECTED_CONTROLLERS_MESSAGE")
            } else {
                ForEach(connectedControllers) { controller in
                    NavigationLink(to: .controllerSettings(controller)) {
                        Label(controller.vendorName ?? "UNKNOWN_CONTROLLER", systemImage: controller.symbol)
                    }
                }
            }
        }
        .onAppear {
            reloadControllers()
            GCController.startWirelessControllerDiscovery()
        }
        .onDisappear(perform: GCController.stopWirelessControllerDiscovery)
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect), perform: controllerNotification)
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidDisconnect), perform: controllerNotification)
    }
    
    func controllerNotification(_: Notification) {
        self.reloadControllers()
    }

    func reloadControllers() {
        self.connectedControllers = GCController.controllers()
    }
}
