import SwiftUI
import EclipseKit
import CoreData

struct LazyControlsProfilePicker<ProfileObject: InputSourceProfileObject, Label: View>: View {
    private let label: () -> Label
    private let system: System
    private let defaultProfileLabel: LocalizedStringKey?
    @State private var state: LoadingState = .pending
    let load: (System) async throws -> ProfileObject?
    let update: (System, ProfileObject?) async throws -> Void
    
    @State private var isPickerOpen: Bool = false
    
    private enum LoadingState: Equatable {
        case pending
        case success(ProfileObject?)
        case failure(any Error)
        
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending): true
            case (.success(let lhsProfile), .success(let rhsProfile)): lhsProfile == rhsProfile
            case (.failure, .failure): false
            default: false
            }
        }
    }

    init(
        _ defaultProfileLabel: LocalizedStringKey? = nil,
        system: System,
        load: @escaping (System) async throws -> ProfileObject?,
        update: @escaping (System, ProfileObject?) async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.system = system
        self.label = label
        self.defaultProfileLabel = defaultProfileLabel
        self.load = load
        self.update = update
    }

    var body: some View {
        LabeledContent {
            switch state {
            case .pending:
                ProgressView()
            case .success(let profile):
                content(profile: profile)
            case .failure:
                content(profile: nil)
            }
        } label: {
            VStack(alignment: .leading) {
                label()
                sublabel
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .task(loadProfile)
        .onChange(of: state, perform: self.stateUpdated)
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .sheet(isPresented: $isPickerOpen) {
            NavigationStack {
                ControlsProfilePickerView(
                    selection: .init(
                        get: {
                            return if case .success(let profileObject) = state {
                                profileObject
                            } else {
                                nil
                            }
                        },
                        set: { self.state = .success($0) }
                    ),
                    system: system
                )
            }
        }
    }
    
    @ViewBuilder
    private var sublabel: some View {
        switch state {
        case .pending:
            Text("LOADING")
        case .success(let profile):
            if let profile {
                Text(verbatim: profile.name, fallback: "PROFILE_UNNAMED")
            } else if let defaultProfileLabel {
                Text(defaultProfileLabel)
            }
        case .failure:
            Text("PROFILE_LOAD_FAILURE").foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private func content(profile: ProfileObject?) -> some View {
        if profile == nil {
            ToggleButton(value: $isPickerOpen) {
                Text("SELECT")
            }
        } else {
            Menu {
                ToggleButton("SELECT_OTHER", value: $isPickerOpen)
                Button("REMOVE", action: self.clear)
            } label: {
                Text("REPLACE")
            }
        }
    }
    
    private func loadProfile() async {
        self.state = .pending
        do {
            let profile = try await self.load(system)
            self.state = .success(profile)
        } catch {
            self.state = .failure(error)
        }
    }
    
    private func clear() {
        self.state = .success(nil)
        Task {
            do {
                try await self.update(system, nil)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
    
    private func stateUpdated(newState: LoadingState) {
        guard case .success(let newProfile) = newState else { return }
        Task {
            do {
                try await self.update(system, newProfile)
            } catch {
                self.state = .failure(error)
            }
        }
    }
}
