import SwiftUI

struct EmptyMessage: View {
    let title: () -> Text
    let message: () -> Text
    
    var body: some View {
        MessageBlock {
            title()
                .fontWeight(.medium)
                .padding([.top, .horizontal], 8.0)
            message()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding([.bottom, .horizontal], 8.0)
        }
    }
}

#Preview {
    EmptyMessage {
        Text("Missing Content")
    } message: {
        Text("Lorem ipsum dolor sunt")
    }
}
