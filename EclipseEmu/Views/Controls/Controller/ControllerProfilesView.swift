import SwiftUI
import EclipseKit
import CoreData
import GameController

struct ControllerProfilesView: View {
    @State var isCreateProfileOpen: Bool = false
    @State var editProfileTarget: InputSourceControllerProfileObject?

    @State var connectedControllers: [GCController] = []

    @FetchRequest(sortDescriptors: [.init(keyPath: \InputSourceControllerProfileObject.name, ascending: true)])
    private var profiles: FetchedResults<InputSourceControllerProfileObject>

    var body: some View {
        Form {
            Section {
                if connectedControllers.isEmpty {
                    EmptyMessage {
                        Text("NO_CONNECTED_CONTROLLERS_TITLE")
                    } message: {
                        Text("NO_CONNECTED_CONTROLLERS_MESSAGE")
                    }
                    .listItem()
                } else {
                    ForEach(connectedControllers) { controller in
                        NavigationLink(to: .controllerSettings(controller)) {
                            Label(controller.vendorName ?? "UNKNOWN_CONTROLLER", systemImage: controller.symbol)
                        }
                    }
                }
            } header: {
                Text("CONNECTED_CONTROLLERS")
            }

            Section {
                if profiles.isEmpty {
                    EmptyMessage {
                        Text("NO_PROFILES_TITLE")
                    } message: {
                        Text("NO_PROFILES_MESSAGE")
                    }
                    .listItem()
                } else {
                    ForEach(profiles) { profile in
                        Button {
                            editProfileTarget = profile
                        } label: {
                            Text(verbatim: profile.name, fallback: "PROFILE_UNNAMED")
                        }
                    }
                }
            } header: {
                Text("PROFILES")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("CONTROLLER_PROFILES_TITLE")
        .refreshable(action: reloadControllers)
        .onAppear {
            reloadControllers()
            GCController.startWirelessControllerDiscovery()
        }
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect), perform: controllerNotification)
        .onReceive(NotificationCenter.default.publisher(for: .GCControllerDidConnect), perform: controllerNotification)
        .onDisappear(perform: GCController.stopWirelessControllerDiscovery)
        .sheet(item: $editProfileTarget) { item in
            NavigationStack {
                ControllerProfileEditorView(for: .edit(item))
                    .navigationTitle("EDIT_PROFILE")
            }
        }
        .sheet(isPresented: $isCreateProfileOpen) {
            NavigationStack {
                ControllerProfileEditorView(for: .create)
                    .navigationTitle("CREATE_PROFILE")
            }
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

    func controllerNotification(_: Notification) {

    }

    func reloadControllers() {
        self.connectedControllers = GCController.controllers()
    }
}

#Preview {
    ControllerProfilesView()
}
