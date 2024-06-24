import SwiftUI

struct ImageAssetView: View {
    var asset: ImageAsset?
    var cornerRadius: CGFloat

    var body: some View {
        AsyncImage(url: asset?.path?.path(in: .shared)) { imagePhase in
            switch imagePhase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            case .failure:
                Image(systemName: "exclamationmark.triangle")
            case .empty:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(.tertiary)
            @unknown default:
                ProgressView()
            }
        }
    }
}
