import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct SettingsGeneralView: View {
    var body: some View {
        Form {
            #if os(macOS)
            Spacer()
            #endif
        }
        .navigationTitle("General")
    }
}

#Preview {
    SettingsGeneralView()
}
