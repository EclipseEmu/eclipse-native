import SwiftUI
import EclipseKit
import GameController

@MainActor
enum Destination: Hashable, Equatable {
	case settings
	case coreSettings(Core)
	case credits
    case license(LicenseItem)

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
}

extension NavigationLink {
    init(to value: Eclipse.Destination, @ViewBuilder label: () -> Label) where Label: View, Destination == Never {
        self = .init(value: value, label: label)
    }

    init(_ titleKey: LocalizedStringKey, systemImage: String, to value: Eclipse.Destination) where Label == SwiftUI.Label<Text, Image>, Destination == Never {
        self = .init(value: value) {
            Label(titleKey, systemImage: systemImage)
        }
    }
    
    init<S: StringProtocol>(verbatim content: S, systemImage: String, to value: Eclipse.Destination) where Label == SwiftUI.Label<Text, Image>, Destination == Never {
        self = .init(value: value) {
            Label(content, systemImage: systemImage)
        }
    }
    

    init(_ titleKey: LocalizedStringKey, to value: Eclipse.Destination) where Label == Text, Destination == Never {
        self = .init(value: value) {
            Text(titleKey)
        }
    }
    
    init<S: StringProtocol>(verbatim content: S, to value: Eclipse.Destination) where Label == Text, Destination == Never {
        self = .init(value: value) {
            Text(content)
        }
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
        case .license(let license):
            LicenseView(license: license)
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
