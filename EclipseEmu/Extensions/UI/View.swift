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
    
    @available(iOS, deprecated: 17.0, message: "Use .onKeyPress instead.")
    @available(macOS, deprecated: 14.0, message: "Use .onKeyPress instead.")
    @ViewBuilder
    func disableKeyboardFeedbackSound() -> some View {
        if #available(iOS 17.0, macOS 10.14, *) {
            self.onKeyPress { _ in .handled }
        } else {
            self
        }
    }
    
    @available(iOS, deprecated: 17.0, message: "Use .onKeyPress instead.")
    @available(macOS, deprecated: 14.0, message: "Use .onKeyPress instead.")
    @ViewBuilder
    func ignoreKeyboardFeedbackSound(for key: KeyEquivalent) -> some View {
        if #available(iOS 17.0, macOS 10.14, *) {
            self.onKeyPress(key) { .handled }
        } else {
            self
        }
    }

    @available(iOS, deprecated: 17.0, message: "Use .onKeyPress instead.")
    @available(macOS, deprecated: 14.0, message: "Use .onKeyPress instead.")
    @ViewBuilder
    func ignoreKeyboardFeedbackSound(for keys: [KeyEquivalent]) -> some View {
        if #available(iOS 17.0, macOS 10.14, *) {
            self.onKeyPress { key in
                if keys.contains(key.key) {
                    .handled
                } else {
                    .ignored
                }
            }
        } else {
            self
        }
    }
}
