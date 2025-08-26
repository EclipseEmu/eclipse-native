import SwiftUI

struct RemoteImageView: View {
    private let url: URL?
    private let aspectRatio: CGFloat
    private let cornerRadius: CGFloat

    init(_ url: URL?, aspectRatio: CGFloat, cornerRadius: CGFloat = 8.0) {
        self.url = url
        self.aspectRatio = aspectRatio
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Color.gray.opacity(0.15)
            .overlay {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Color.gray
                    default:
                        Color.clear
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(style: .init(lineWidth: 1))
                    .foregroundStyle(Color.gray)
                    .opacity(0.15)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .aspectRatio(aspectRatio, contentMode: .fit)
    }
}
