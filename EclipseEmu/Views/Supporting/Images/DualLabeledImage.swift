import SwiftUI

struct DualLabeledImage<Overlay: View>: View {
    @EnvironmentObject private var persistence: Persistence
    
    private let title: Text
    private let subtitle: Text
    private let image: ImageAssetObject?
    private let aspectRatio: CGFloat
    private let cornerRadius: CGFloat
    private let idealWidth: CGFloat?
    private let overlayAlignment: Alignment
    private let overlay: () -> Overlay

    init(
        title: Text,
        subtitle: Text,
        image: ImageAssetObject?,
        aspectRatio: CGFloat = 1.0,
        cornerRadius: CGFloat = 8.0,
        idealWidth: CGFloat? = nil,
        overlayAlignment: Alignment = .bottomLeading,
        @ViewBuilder overlay: @escaping () -> Overlay,
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
        self.idealWidth = idealWidth
        self.overlayAlignment = overlayAlignment
        self.overlay = overlay
    }

    var body: some View {
        VStack(alignment: .leading) {
            RemoteImageView(persistence.files.url(path: image?.path), aspectRatio: aspectRatio, cornerRadius: cornerRadius)
                .overlay(alignment: overlayAlignment, content: overlay)
                .frame(idealWidth: idealWidth)
            
            title
                .font(.footnote.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(Color.primary)
            subtitle
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}
