import SwiftUI
import EclipseKit
import CoreData

struct ControlsProfilePicker<ProfileObject: ControlsProfileObject, Label: View>: View {
	@Binding private var profile: ProfileObject?
	private let system: System
    private let defaultProfileLabel: LocalizedStringKey?
    private let label: () -> Label

	@State private var isPickerOpen: Bool = false

    init(
        profile: Binding<ProfileObject?>,
        defaultProfileLabel: LocalizedStringKey? = nil,
        system: System,
        @ViewBuilder label: @escaping () -> Label
    ) {
		self._profile = profile
		self.system = system
		self.label = label
        self.defaultProfileLabel = defaultProfileLabel
	}

	var body: some View {
		LabeledContent {
			if profile == nil {
				ToggleButton(value: $isPickerOpen) {
                    Text("SELECT")
				}
			} else {
				Menu {
					ToggleButton("SELECT_OTHER", value: $isPickerOpen)
					Button("REMOVE") {
						self.profile = nil
					}
				} label: {
					Text("REPLACE")
				}
			}
		} label: {
			VStack(alignment: .leading) {
				label()
                sublabel
                    .foregroundStyle(.secondary)
                    .font(.caption)
			}
		}
		.buttonStyle(.bordered)
		.buttonBorderShape(.capsule)
		.sheet(isPresented: $isPickerOpen) {
            FormSheetView {
                ControlsProfilePickerView(selection: $profile, system: system)
			}
		}
	}
    
    @ViewBuilder
    var sublabel: some View {
        if let profile {
            Text(verbatim: profile.name, fallback: "PROFILE_UNNAMED")
        } else if let defaultProfileLabel {
            Text(defaultProfileLabel)
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    @Previewable @State var profile: KeyboardProfileObject?
    NavigationStack {
        ControlsProfilePicker(profile: $profile, system: .gba) {
            Text("KEYBOARD")
        }
    }
}

