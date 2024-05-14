import SwiftUI

/// A compatibility layer for NavigationStack, since we support iOS 15 which does not support the newer navigation APIs.
struct CompatNavigationStack<Content: View>: View {
    var content: () -> Content

    var body: some View {
        #if os(iOS)
        if #unavailable(iOS 16.0) {
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
        NavigationLink(destination: Text("Hello, world").navigationTitle("Test 2"), label: {
            Text("Hello, world")
        }).navigationTitle("Test 1")
    }
}
