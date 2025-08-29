import SwiftUI

@available(iOS, deprecated: 26.0, renamed: "View.glassEffect", message: "Use the glassEffect view modifier instead.")
@available(macOS, deprecated: 26.0, renamed: "View.glassEffect", message: "Use the glassEffect view modifier instead.")
struct GlassyBackgroundViewModifier<S: Shape>: ViewModifier {
    let shape: S
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.background(Material.ultraThick).clipShape(shape)
        }
    }
}

extension View {
    @available(iOS, deprecated: 26.0, renamed: "View.glassEffect", message: "Use the glassEffect view modifier instead.")
    @available(macOS, deprecated: 26.0, renamed: "View.glassEffect", message: "Use the glassEffect view modifier instead.")
    func glassyBackground<S: Shape>(_ shape: S) -> some View {
        self.modifier(GlassyBackgroundViewModifier(shape: shape))
    }
}
