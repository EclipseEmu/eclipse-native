import SwiftUI

struct DualLabeledImage<Content: View>: View {
    let image: () -> Content
    let title: Text
    let subtitle: Text

    init(title: Text, subtitle: Text, @ViewBuilder image: @escaping () -> Content) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                image()
                title
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
                subtitle
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
