import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct DataPointView: View {
    var title: LocalizedStringKey
    var content: () -> Text

    var body: some View {
        VStack {
            Text(title)
                .font(.callout)
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
