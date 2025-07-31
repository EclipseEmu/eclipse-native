import SwiftUI
import EclipseKit

struct CreateControlsProfileView<ProfileObject: ControlsProfileObject>: View {
    private typealias ControlsSource = CopyProfileControlsSource<ProfileObject>
    
    @EnvironmentObject private var persistence: Persistence
    @Environment(\.dismiss) private var dismiss: DismissAction
    @EnvironmentObject private var navigation: NavigationManager
    @State private var name: String = ""
	@State private var system: System = .unknown
    @State private var controlsSource: Self.ControlsSource.Parts = .init(.nowhere)

	var body: some View {
		Form {
			Section {
				LabeledContent {
					TextField("NAME", text: $name)
						.labelsHidden()
						.multilineTextAlignment(.trailing)
				} label: {
					Text("NAME")
				}

				Picker("SYSTEM", selection: $system) {
					Text("Unselected").tag(System.unknown)
					Divider()
					ForEach(System.concreteCases, id: \.rawValue) { system in
						Text(system.string).tag(system)
					}
				}
			} footer: {
				Text("Use the system default controls in this profile, or start from scratch.")
			}

			Section {
                Picker(selection: $controlsSource.sourceType) {
                    Text("Nowhere").tag(Self.ControlsSource.SourceType.nowhere)
					Text("System Defaults").tag(Self.ControlsSource.SourceType.systemDefaults)
					Text("Other Profile").tag(Self.ControlsSource.SourceType.otherProfile)
				} label: {
					Text("Copy Controls From")
				}
                if controlsSource.sourceType == .otherProfile {
                    ControlsProfilePicker(profile: $controlsSource.otherProfile, system: system) {
						Text("Other Profile")
					}
					.disabled(system == .unknown)
				}
			}
		}
		.formStyle(.grouped)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				DismissButton("CANCEL")
			}
			ToolbarItem(placement: .confirmationAction) {
				ConfirmButton("CREATE", action: create)
                    .disabled(name.isEmpty || system == .unknown || (controlsSource.sourceType == .otherProfile && controlsSource.otherProfile == nil))
			}
		}
		.navigationTitle("Create Profile")
		.navigationBarTitleDisplayMode(.inline)
	}

	func create() {
        Task {
            do {
                let profileBox = try await persistence.objects.createProfile(
                    name: self.name,
                    system: system,
                    copying: .init(from: self.controlsSource)
                )
                
                dismiss()
                
                if let profile = profileBox.tryGet(in: persistence.mainContext) {
                    let destination = ProfileObject.navigationDestination(profile)
                    navigation.path.append(destination)
                }
            } catch {
                // FIXME: Surface error
                print("failed to create profile:", error)
            }
        }
	}
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    NavigationStack {
        CreateControlsProfileView<KeyboardProfileObject>()
    }
}
