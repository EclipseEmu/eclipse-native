import SwiftUI

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
