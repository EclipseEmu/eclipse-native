import SwiftUI

struct LocalImage<I: View, P: View>: View {
    @EnvironmentObject var persistence: Persistence
    private var handle: ImageAsset?
    private let image: (Image) -> I
    private let placeholder: () -> P

    init(
        _ object: ImageAsset?,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) {
        self.handle = object
        self.image = image
        self.placeholder = placeholder
    }

    var body: some View {
        AsyncImage(url: persistence.files.url(path: handle?.path)) { phase in
            switch phase {
            case .success(let image):
                self.image(image)
            case .failure:
                Color.gray
            default:
                placeholder()
            }
        }
    }
}
