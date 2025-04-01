import SwiftUI

struct DataPointView: View {
    var title: LocalizedStringKey
    var content: () -> Text

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            content()
                .foregroundStyle(.secondary)
                .font(.caption)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DataPointView(title: "Some Data") {
        Text("Hello, world")
    }
    .padding()
}
