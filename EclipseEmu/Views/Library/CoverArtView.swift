import SwiftUI

struct CoverArtView: View {
    var image: ImageAssetObject?
    
    init(_ image: ImageAssetObject?) {
        self.image = image
    }
    
    var body: some View {
        Color.gray.opacity(0.15)
            .overlay {
                LocalImage(image) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.clear
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8.0)
                    .stroke(style: .init(lineWidth: 1))
                    .foregroundStyle(Color.gray)
                    .opacity(0.15)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.0))
            .aspectRatio(1.0, contentMode: .fit)
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview(traits: .previewStorage) {
    PreviewSingleObjectView(GameObject.fetchRequest()) { game, _ in
        CoverArtView(game.cover)
    }
}
