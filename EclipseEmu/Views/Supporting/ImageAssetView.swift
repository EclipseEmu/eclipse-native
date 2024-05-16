import SwiftUI

struct ImageAssetView: View {
    @Environment(\.persistenceCoordinator) var persistence
    var asset: ImageAsset?
    var cornerRadius: CGFloat
    
    var body: some View {
        AsyncImage(url: asset?.path(in: persistence)) { imagePhase in
            switch imagePhase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            case .failure(_):
                Image(systemName: "exclamationmark.triangle")
            case .empty:
                ProgressView()
            @unknown default:
                ProgressView()
            }
        }
    }
}
