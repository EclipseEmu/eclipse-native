import SwiftUI
import EclipseKit
import CoreData

// FIXME: This is causing an infinite loop on macOS, but is perfectly fine on iOS?

struct ControlsProfilePicker<ProfileObject: ControlsProfileObject, Label: View>: View {
	@Binding private var profile: ProfileObject?
	private let label: () -> Label
	private let system: System
    private let defaultProfileLabel: LocalizedStringKey?
    private let loading: Bool
    
	@State private var isPickerOpen: Bool = false

    init(profile: Binding<ProfileObject?>, defaultProfileLabel: LocalizedStringKey? = nil, system: System, loading: Bool = false, @ViewBuilder label: @escaping () -> Label) {
		self._profile = profile
		self.system = system
		self.label = label
        self.defaultProfileLabel = defaultProfileLabel
        self.loading = loading
	}

	var body: some View {
		LabeledContent {
			if profile == nil {
				ToggleButton(value: $isPickerOpen) {
					if profile == nil {
						Text("SELECT")
					} else {
						Text("REPLACE")
					}
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
        .disabled(loading)
		.sheet(isPresented: $isPickerOpen) {
			NavigationStack {
                ControlsProfilePickerView(selection: $profile, system: system)
			}
		}
	}
    
    @ViewBuilder
    var sublabel: some View {
        if loading {
            Text("LOADING")
        } else if let profile {
            Text(verbatim: profile.name, fallback: "PROFILE_UNNAMED")
        } else if let defaultProfileLabel {
            Text(defaultProfileLabel)
        }
    }
}

private struct ControlsProfilePickerView<ProfileObject: ControlsProfileObject>: View {
	@Environment(\.dismiss) private var dismiss: DismissAction

	@Binding private var selection: ProfileObject?
	private let system: System
	@State private var query: String = ""
    @FetchRequest(sortDescriptors: [.init(keyPath: \ProfileObject.name, ascending: true)])
	private var profiles: FetchedResults<ProfileObject>

	init(selection: Binding<ProfileObject?>, system: System) {
		self._selection = selection
		self.system = system

        let fetchRequest: NSFetchRequest<ProfileObject> = ProfileObject.fetchRequest() as! NSFetchRequest<ProfileObject>
        fetchRequest.sortDescriptors = [.init(keyPath: \ProfileObject.name, ascending: true)]
		fetchRequest.predicate = Self.predicate(query: "", system: system)
		self._profiles = .init(fetchRequest: fetchRequest)
	}

    @ViewBuilder
    var content: some View {
        if profiles.isEmpty && query.isEmpty {
            ContentUnavailableMessage {
                Label("NO_PROFILES_TITLE", systemImage: "magnifyingglass")
            } description: {
                Text("NO_PROFILES_MESSAGE")
            }
        } else if profiles.isEmpty {
            ContentUnavailableMessage.search(text: query)
        } else {
            List(profiles) { profile in
                LabeledContent {
                    Button("USE") {
                        self.selectProfile(profile)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                } label: {
                    Text(verbatim: profile.name, fallback: "PROFILE_UNNAMED")
                }
            }
        }
    }

	var body: some View {
        content
            .navigationTitle("PROFILES")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton("CANCEL")
                }
            }
            .searchable(text: $query)
            .onChange(of: query) { newValue in
                self.profiles.nsPredicate = Self.predicate(query: newValue, system: system)
            }
	}

	func selectProfile(_ newProfile: ProfileObject) {
		self.selection = newProfile
		dismiss()
	}

	static func predicate(query: String, system: System) -> NSPredicate {
		if query.isEmpty {
			NSPredicate(format: "rawSystem = %d", system.rawValue)
		} else {
			NSPredicate(format: "rawSystem = %d AND name CONTAINS[d] %@", system.rawValue, query)
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

