import SwiftUI

struct MessageBlock<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        VStack {
            self.content()
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity)
        .backgroundSecondary()
        .clipShape(RoundedRectangle(cornerRadius: 12.0))
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
}

#Preview {
    MessageBlock {
        Text("Lorem ipsum")
    }
}
