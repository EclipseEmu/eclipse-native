import SwiftUI
import EclipseKit
import CoreData

struct KeyboardProfilesView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        ControlsProfilesView(title: "KEYBOARD_PROFILES_TITLE", settings: $settings.keyboardSystemProfiles)
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage())) {
    NavigationStack {
        KeyboardProfilesView()
    }
}
