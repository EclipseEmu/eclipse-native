import SwiftUI

struct FormSheetView<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    #if os(macOS)
    var body: some View {
        content()
    }
    #else
    var body: some View {
        NavigationStack {
            content()
        }
    }
    #endif
}
