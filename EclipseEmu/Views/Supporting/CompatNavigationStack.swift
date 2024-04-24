import SwiftUI

struct CompatNavigationStack<Content: View>: View {
    var content: () -> Content

    var body: some View {
        #if os(iOS)
        if #unavailable(iOS 16.00) {
            NavigationView {
                content()
            }.navigationViewStyle(.stack)
        } else {
            NavigationStack {
                content()
            }
        }
        #else
        NavigationStack {
            content()
        }
        #endif
    }
}

#Preview {
    CompatNavigationStack {
        Text("Hello, world")
    }
}
