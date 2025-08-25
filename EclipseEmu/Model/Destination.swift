import SwiftUI
import EclipseKit
import GameController

@MainActor
enum Destination: Hashable, Equatable {
	case settings
	case coreSettings(Core)
	case credits
	case licenses

	case keyboardProfiles
    case keyboardProfile(KeyboardProfileObject)

	case controllerProfiles
    case controllerSettings(GCController)
    case controllerProfile(ControllerProfileObject)

#if canImport(UIKit)
	case touchProfiles
	case touchProfile(TouchProfileObject)
	case touchEditorVariant(Int, TouchEditorViewModel)
#endif

	case manageTags
	case editTag(TagObject)
}

extension NavigationLink where Label: View, Destination == Never {
	init(to value: Eclipse.Destination, @ViewBuilder label: () -> Label) {
		self = .init(value: value, label: label)
	}
}

extension Destination {
	@ViewBuilder
	func navigationDestination(_ destination: Destination, coreRegistry: CoreRegistry) -> some View {
		switch destination {
		case .settings:
			SettingsView()
		case .coreSettings(let core):
			core.settingsView
		case .credits:
			CreditsView()
		case .licenses:
			LicensesView()
		case .manageTags:
			TagsView()
		case .editTag(let tag):
			EditTagView(mode: .edit(tag))
		case .keyboardProfiles:
			KeyboardProfilesView()
        case .keyboardProfile(let profile):
            KeyboardProfileView(profile: profile)
        case .controllerProfiles:
            ControllerProfilesView()
        case .controllerProfile(let profile):
            ControllerProfileView(profile: profile)
		case .controllerSettings(let controller):
			ControllerSettingsView(controller: controller)
#if canImport(UIKit)
		case .touchProfiles:
			TouchProfilesView()
		case .touchProfile(let profile):
			TouchProfileView(profile: profile)
		case .touchEditorVariant(let target, let viewModel):
			TouchEditorVariantView(viewModel: viewModel, target: target)
#endif
		}
	}
}
