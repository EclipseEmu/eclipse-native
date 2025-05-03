import SwiftUI
import EclipseKit
import CoreData

struct KeyboardProfilesView: View {
    @State var isCreateProfileOpen: Bool = false
    @State var editProfileTarget: InputSourceKeyboardProfileObject?

    @FetchRequest(sortDescriptors: [.init(keyPath: \InputSourceKeyboardProfileObject.name, ascending: true)])
    private var profiles: FetchedResults<InputSourceKeyboardProfileObject>

    var body: some View {
        Form {
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
        .navigationTitle("KEYBOARD_PROFILES_TITLE")
        .sheet(item: $editProfileTarget) { item in
            NavigationStack {
                KeyboardProfileEditorView(for: .edit(item))
                    .navigationTitle("EDIT_PROFILE")
            }
        }
        .sheet(isPresented: $isCreateProfileOpen) {
            NavigationStack {
                KeyboardProfileEditorView(for: .create)
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
}
