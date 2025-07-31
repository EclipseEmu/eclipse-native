import SwiftUI

extension View {
    func persistence(_ persistence: Persistence) -> some View {
        self
            .environmentObject(persistence)
            .environment(\.managedObjectContext, persistence.mainContext)
    }

    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> T {
        return modifier(self)
    }

    @ViewBuilder
    func hidden(if isHidden: Bool) -> some View {
        if !isHidden {
            self
        }
    }

    @ViewBuilder
    func backgroundSecondary() -> some View {
#if canImport(UIKit)
            if #available(iOS 17.0, macOS 14.0, *) {
                self.background(.background.secondary)
            } else {
                self.background(Color(uiColor: .secondarySystemBackground))
            }
#else
            if #available(macOS 14.0, *) {
                self.background(Color(nsColor: .tertiarySystemFill))
            } else {
                self.background(Color(nsColor: .gridColor))
            }
#endif
    }
}
