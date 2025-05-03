import SwiftUI

struct EmptyMessage: View {
    let title: () -> Text
    let message: () -> Text

    var body: some View {
        VStack {
            title()
                .font(.subheadline)
                .fontWeight(.medium)
                .padding([.top, .horizontal], 8.0)
            message()
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding([.bottom, .horizontal], 8.0)
        }
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    func freestanding() -> some View {
        self
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
            .backgroundSecondary()
            .clipShape(RoundedRectangle(cornerRadius: 12.0))
            .padding(.horizontal)
    }

    @ViewBuilder
    func listItem() -> some View {
        self
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
    }
}

#Preview("Freestanding") {
    EmptyMessage {
        Text("Missing Content")
    } message: {
        Text("Lorem ipsum dolor sunt")
    }
    .freestanding()
}

#Preview("List") {
    List {
        EmptyMessage {
            Text("Missing Content")
        } message: {
            Text("Lorem ipsum dolor sunt")
        }
        .listItem()
    }
}
