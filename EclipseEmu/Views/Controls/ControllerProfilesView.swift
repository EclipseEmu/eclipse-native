import SwiftUI
import EclipseKit
import CoreData
import GameController

struct ControllerProfilesView: View {
    @State var isCreateProfileOpen: Bool = false
    @State var editProfileTarget: ControllerProfile?

    @State var connectedControllers: [GCController] = []

    // FIXME: make this a fetch request.
    var profiles: [ControllerProfile] = []

    var body: some View {
        List {
            Section {
                ForEach(connectedControllers) { controller in
                    NavigationLink(to: .controllerSettings(controller)) {
                        Label(controller.vendorName ?? "UNKNOWN_CONTROLLER", systemImage: controller.symbol)
                    }
                }
            } header: {
                Text("CONNECTED_CONTROLLERS")
            }

            Section {
                ForEach(profiles) { profile in
                    Button {
                        editProfileTarget = profile
                    } label: {
                        Text(profile.name)
                    }
                }
            } header: {
                Text("PROFILES")
            }
        }
        .refreshable(action: reloadControllers)
        .onAppear {
            reloadControllers()
            GCController.startWirelessControllerDiscovery()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect)) { _ in
            reloadControllers()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect)) { _ in
            reloadControllers()
        }
        .onDisappear(perform: GCController.stopWirelessControllerDiscovery)
        .sheet(item: $editProfileTarget) { item in
            ControllerProfileEditorView(for: .edit(item))
        }
        .sheet(isPresented: $isCreateProfileOpen) {
            ControllerProfileEditorView(for: .create)
        }
        .toolbar {
            #if !os(macOS)
            EditButton()
            #endif
            ToggleButton(value: $isCreateProfileOpen) {
                Label("CREATE_PROFILE", systemImage: "plus")
            }
        }
    }

    func reloadControllers() {
        self.connectedControllers = GCController.controllers()
    }
}
