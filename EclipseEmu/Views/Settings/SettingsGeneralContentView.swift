import SwiftUI

struct SettingsGeneralContentView: View {
    var body: some View {
        Section("ABOUT") {
            NavigationLink("CREDITS", systemImage: "person", to: .credits)
            LinkItemView("HELP_AND_GUIDES", systemImage: "questionmark", to: URL(string: "https://eclipseemu.me/")!)
            LinkItemView("WHATS_NEW", systemImage: "doc.badge.clock", to: URL(string: "https://eclipseemu.me/")!)
        }
        .buttonStyle(.borderless)
        .labelStyle(.titleOnly)

        Section("SOCIAL") {
            LinkItemView("DISCORD", systemImage: "app.dashed", to: URL(string: "https://discord.gg/Mx2W9nec4Z")!)
            LinkItemView("GITHUB", systemImage: "app.dashed", to: URL(string: "https://github.com/EclipseEmu")!)
        }
        .buttonStyle(.borderless)
        .labelStyle(.titleOnly)
        
#if !os(macOS)
        Section {} footer: {
            VStack(alignment: .center) {
                Rectangle()
                    .overlay { AppIconView() }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 11.0))
                Text("v\(Bundle.main.releaseVersionNumber ?? "") (\(Bundle.main.buildVersionNumber ?? ""))")
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        }
#endif
    }
}
