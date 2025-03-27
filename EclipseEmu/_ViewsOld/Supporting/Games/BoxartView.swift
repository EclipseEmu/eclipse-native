import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct BoxartView: View {
    @ObservedObject var game: Game
    let cornerRadius: CGFloat

    var body: some View {
        ImageAssetView(asset: game.boxart, cornerRadius: cornerRadius)
            .aspectRatio(1.0, contentMode: .fit)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineWidth: 1.0)
                    .foregroundStyle(.secondary)
                    .opacity(0.25)
            }
    }
}
