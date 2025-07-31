#if canImport(UIKit)
import SwiftUI
import EclipseKit
import CoreData

struct TouchProfilesView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        ControlsProfilesView(title: "TOUCH_PROFILES_TITLE", settings: $settings.touchSystemProfiles)
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    NavigationStack {
		TouchProfilesView()
	}
}
#endif
