import SwiftUI

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> T {
        return modifier(self)
    }

    func persistence(_ persistence: Persistence) -> some View {
        self
            .environmentObject(persistence)
            .environment(\.managedObjectContext, persistence.mainContext)
    }
    
    // FIXME: Figure out how to do the following on older OS versions...

    @available(iOS, deprecated: 17.0, message: "Use .onKeyPress instead.")
    @available(macOS, deprecated: 14.0, message: "Use .onKeyPress instead.")
    @ViewBuilder
    func makeFocusable() -> some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            self.focusable().focusEffectDisabled()
        } else {
            self
        }
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
