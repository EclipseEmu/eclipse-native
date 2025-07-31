import SwiftUI
import EclipseKit
import CoreData

struct ControlsProfilesView<ProfileObject: ControlsProfileObject, ExtraContent: View>: View {
    let title: LocalizedStringKey
    let extraContent: () -> ExtraContent
    @Binding var settings: [System : ObjectBox<ProfileObject>]

    @EnvironmentObject private var persistence: Persistence
    @State private var isCreateProfileOpen: Bool = false
    @SectionedFetchRequest(sectionIdentifier: \ProfileObject.rawSystem, sortDescriptors: [.init(keyPath: \ProfileObject.name, ascending: true)])
    private var sections: SectionedFetchResults<Int16, ProfileObject>
    
    init(title: LocalizedStringKey, settings: Binding<[System : ObjectBox<ProfileObject>]>, @ViewBuilder extraContent: @escaping () -> ExtraContent) {
        self.title = title
        self._settings = settings
        self.extraContent = extraContent
    }
    
    var body: some View {
        Form {
            Section("SYSTEMS") {
                ControlsSystemProfilesView(load: loadProfile, update: setProfile)
            }
            
            extraContent()
            
            if sections.isEmpty {
                Section("PROFILES") {
                    EmptyMessage.listItem(title: "NO_PROFILES_TITLE", message: "NO_PROFILES_MESSAGE")
                }
            } else {
                ForEach(sections) { section in
                    Section {
                        ForEach(section) { profile in
                            NavigationLink(to: ProfileObject.navigationDestination(profile)) {
                                Text(verbatim: profile.name, fallback: "PROFILE_UNNAMED")
                            }
                        }
                    } header: {
                        if let system = System(rawValue: UInt16(section.id)) {
                            Text(system.string)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(title)
        .toolbar {
#if !os(macOS)
            EditButton()
#endif
            ToggleButton(value: $isCreateProfileOpen) {
                Label("CREATE_PROFILE", systemImage: "plus")
            }
        }
        .sheet(isPresented: $isCreateProfileOpen) {
            NavigationStack {
                CreateControlsProfileView<ProfileObject>()
            }
        }
    }

    func loadProfile(for system: System) -> ProfileObject? {
        settings[system]?.tryGet(in: persistence.mainContext)
    }

    func setProfile(for system: System, to profile: ProfileObject?) {
        if let profile {
            settings[system] = .init(profile)
        } else {
            settings.removeValue(forKey: system)
        }
    }
}

extension ControlsProfilesView where ExtraContent == EmptyView {
    init(title: LocalizedStringKey, settings: Binding<[System : ObjectBox<ProfileObject>]>) {
        self.title = title
        self.extraContent = { EmptyView() }
        self._settings = settings
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    NavigationStack {
        TouchProfilesView()
    }
}

