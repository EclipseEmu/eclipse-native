import SwiftUI
import EclipseKit
import CoreData

struct KeyboardProfilesView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        ControlsProfilesView<InputSourceKeyboardDescriptor, _>(title: "KEYBOARD_PROFILES_TITLE", settings: $settings.keyboardSystemProfiles)
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .previewStorage) {
    NavigationStack {
        KeyboardProfilesView()
    }
}
