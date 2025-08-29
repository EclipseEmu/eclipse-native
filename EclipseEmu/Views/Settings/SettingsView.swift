import SwiftUI
import EclipseKit

struct SettingsView: View {
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Form {
			Section("CONTROLS") {
				#if canImport(UIKit)
				NavigationLink("TOUCH", to: .touchProfiles)
				#endif
                NavigationLink("KEYBOARD", to: .keyboardProfiles)
                NavigationLink("CONTROLLERS", to: .controllerProfiles)
            }

            SettingsEmulationContentView()
            
            Section("CORES") {
				ForEach(Core.allCases) { core in
                    NavigationLink(verbatim: core.type.name, to: .coreSettings(core))
                }
            }
            
            SettingsGeneralContentView()
        }
        .navigationTitle("SETTINGS")
        .formStyle(.grouped)
    }
}

#Preview {
    let settings = Settings()
    NavigationStack {
        SettingsView()
            .environmentObject(CoreRegistry())
            .environmentObject(settings)
    }
}
