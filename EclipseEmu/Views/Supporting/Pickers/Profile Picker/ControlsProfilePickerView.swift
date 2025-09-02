import SwiftUI
import EclipseKit
import CoreData

struct ControlsProfilePickerView<ProfileObject: InputSourceProfileObject>: View {
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
            ContentUnavailableMessage("NO_PROFILES_TITLE", systemImage: "magnifyingglass", description: "NO_PROFILES_MESSAGE")
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
            #if os(macOS)
            .frame(minHeight: 300, maxHeight: .infinity)
            #endif
        }
    }

	var body: some View {
        content
            .navigationTitle("PROFILES")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query)
            .onChange(of: query) { newValue in
                self.profiles.nsPredicate = Self.predicate(query: newValue, system: system)
            }
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CancelButton("CANCEL", action: dismiss.callAsFunction)
                }
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

#Preview {
    FormSheetView {
        ControlsProfilePickerView<KeyboardProfileObject>(selection: .constant(nil), system: .gba)
    }
}
