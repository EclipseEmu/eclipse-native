import SwiftUI

extension View {
    func persistence(_ persistence: Persistence) -> some View {
        self
            .environmentObject(persistence)
            .environment(\.managedObjectContext, persistence.mainContext)
    }

    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }

    func fullWidthFrame() -> some View {
        self.frame(minWidth: .zero, maxWidth: .infinity)
    }

    func backgroundSecondary() -> some View {
        self.modify {
#if canImport(UIKit)
            if #available(iOS 17.0, macOS 14.0, *) {
                $0.background(.background.secondary)
            } else {
                $0.background(Color(uiColor: .secondarySystemBackground))
            }
#else
            if #available(macOS 14.0, *) {
                $0.background(Color(nsColor: .tertiarySystemFill))
            } else {
                $0.background(Color(nsColor: .gridColor))
            }
#endif
        }
    }

    @available(*, deprecated, renamed: "background", message: "")
    func backgroundGradient(color: Color) -> some View {
        return self.background(color.gradient)
    }
}
