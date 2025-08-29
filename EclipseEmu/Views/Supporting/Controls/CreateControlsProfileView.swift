import SwiftUI
import EclipseKit

struct CreateControlsProfileView<InputSource: InputSourceDescriptorProtocol>: View {
    private typealias ControlsSource = CopyProfileControlsSource<InputSource.Object>
    
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
					Text("UNSELECTED").tag(System.unknown)
					Divider()
					ForEach(System.concreteCases, id: \.rawValue) { system in
						Text(system.string).tag(system)
					}
				}
			}

			Section {
                Picker(selection: $controlsSource.sourceType) {
                    Text("CONTROLS_SOURCE_SYSTEM_NOWHERE").tag(Self.ControlsSource.SourceType.nowhere)
					Text("CONTROLS_SOURCE_SYSTEM_DEFAULTS").tag(Self.ControlsSource.SourceType.systemDefaults)
					Text("CONTROLS_SOURCE_OTHER_PROFILE").tag(Self.ControlsSource.SourceType.otherProfile)
				} label: {
					Text("CONTROLS_SOURCE")
				}
                if controlsSource.sourceType == .otherProfile {
                    ControlsProfilePicker(profile: $controlsSource.otherProfile, system: system) {
						Text("CONTROLS_SOURCE_OTHER_PROFILE")
					}
					.disabled(system == .unknown)
				}
            } footer: {
                Text("CONTROLS_SOURCE_EXPLAINER")
			}
		}
		.formStyle(.grouped)
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
                CancelButton(action: dismiss.callAsFunction)
			}
			ToolbarItem(placement: .confirmationAction) {
				ConfirmButton("CREATE", action: create)
                    .disabled(name.isEmpty || system == .unknown || (controlsSource.sourceType == .otherProfile && controlsSource.otherProfile == nil))
			}
		}
		.navigationTitle("CREATE_PROFILE")
#if canImport(UIKit)
        .navigationBarTitleDisplayMode(.inline)
#endif
	}

	func create() {
        Task {
            do {
                let profileBox = try await persistence.objects.createProfile(
                    InputSource.self,
                    name: self.name,
                    system: system,
                    copying: .init(from: self.controlsSource)
                )
                
                dismiss()
                
                if let profile = profileBox.tryGet(in: persistence.mainContext) {
                    let destination = InputSource.Object.navigationDestination(profile)
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
#Preview(traits: .previewStorage) {
    NavigationStack {
        CreateControlsProfileView<InputSourceKeyboardDescriptor>()
    }
}
