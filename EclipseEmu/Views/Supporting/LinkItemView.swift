import SwiftUI

struct LinkItemView<Label: View>: View {
    private let url: URL
    private let label: () -> Label

    init(to url: URL, @ViewBuilder label: @escaping () -> Label) {
        self.url = url
        self.label = label
    }

    init(_ titleKey: LocalizedStringKey, systemImage: String, to url: URL) where Label == SwiftUI.Label<Text, Image> {
        self.url = url
        self.label = { SwiftUI.Label(titleKey, systemImage: systemImage) }
    }
    
    var body: some View {
        Link(destination: url) {
            HStack {
                label()
                    .foregroundStyle(Color.primary)
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}
