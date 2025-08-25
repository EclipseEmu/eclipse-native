import SwiftUI

struct EmptyMessage: View {
    let title: () -> Text
    let message: () -> Text
    
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
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding()
    }
}

#Preview {
    List {
        EmptyMessage(title: "DONE", message: "DONE")
    }
}
