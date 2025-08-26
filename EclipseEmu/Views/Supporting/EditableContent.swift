import SwiftUI

struct EditableContent<Label: View>: View {
	let action: () -> Void
	let label: () -> Label

	init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
		self.action = action
		self.label = label
	}
    
    init(_ titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) where Label == SwiftUI.Label<Text, Image> {
        self.action = action
        self.label = { Label(titleKey, systemImage: systemImage) }
    }
    
    init(verbatim titleKey: String, systemImage: String, action: @escaping () -> Void) where Label == SwiftUI.Label<Text, Image> {
        self.action = action
        self.label = { Label(titleKey, systemImage: systemImage) }
    }
    
    init(verbatim titleKey: String?, fallback: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) where Label == SwiftUI.Label<Text, Image> {
        self.action = action
        self.label = {
            Label {
                Text(verbatim: titleKey, fallback: fallback)
            } icon: {
                Image(systemName: systemImage)
            }
        }
    }

	var body: some View {
		LabeledContent(content: {
			Button("EDIT", action: action)
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
		}, label: label)
	}
}
