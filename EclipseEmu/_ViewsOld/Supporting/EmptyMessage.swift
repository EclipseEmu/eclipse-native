import SwiftUI

struct EmptyMessage: View {
    let title: () -> Text
    let message: () -> Text

    var body: some View {
        VStack {
            title()
                .fontWeight(.medium)
                .padding([.top, .horizontal], 8.0)
            message()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding([.bottom, .horizontal], 8.0)
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
    EmptyMessage {
        Text("Missing Content")
    } message: {
        Text("Lorem ipsum dolor sunt")
    }
}
