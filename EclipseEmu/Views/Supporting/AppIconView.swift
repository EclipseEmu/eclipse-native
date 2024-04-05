import SwiftUI

struct AppIconView: View {
    #if canImport(UIKit)
        private func iconImage() -> Image? {
            guard
                let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
                let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
                let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
                let iconName = iconFiles.last,
                let image = UIImage(named: iconName)
            else { return nil }
            return Image(uiImage: image)
        }
    #else
        private func iconImage() -> Image? {
            guard let image = Bundle.main.image(forResource: "AppIcon") else { return nil }
            return Image(nsImage: image)
        }
    #endif

    var body: some View {
        if let image = iconImage() {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}
