import SwiftUI

struct EmptyMessage: View {
    let title: () -> Text
    let message: () -> Text
    
    init(title: @escaping () -> Text, message: @escaping () -> Text) {
        self.title = title
        self.message = message
    }
    
    init(title: LocalizedStringKey, message: LocalizedStringKey) {
        self.title = { Text(title) }
        self.message = { Text(message) }
    }
    
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
    static func listItem(title: @escaping () -> Text, message: @escaping () -> Text) -> some View {
        EmptyMessage(title: title, message: message)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
    }
    
    @ViewBuilder
    static func listItem(title: LocalizedStringKey, message: LocalizedStringKey) -> some View {
        Self.listItem(title: { Text(title) }, message: { Text(message) })
    }
}

#Preview("List") {
    List {
        EmptyMessage.listItem {
            Text("Missing Content")
        } message: {
            Text("Lorem ipsum dolor sunt")
        }
    }
}
