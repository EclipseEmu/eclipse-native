import SwiftUI

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
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
    
    func backgroundGradient(color: Color) -> some View {
        return self.modify {
            if #available(iOS 16.0, *) {
                $0.background(color.gradient)
            } else {
                $0.background(color)
            }
        }
    }
}
