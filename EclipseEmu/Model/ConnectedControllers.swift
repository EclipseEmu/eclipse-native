import GameController

final class ConnectedControllers: ObservableObject {
    @Published var controllers: [GCController] = []
    
    func reload() {
        controllers = GCController.controllers()
    }

    func start() {
        GCController.startWirelessControllerDiscovery()
        self.reload()
    }
    
    func stop() {
        GCController.stopWirelessControllerDiscovery()
    }
    
    func handleNotification(_: Notification) {
        self.reload()
    }
}
