import SwiftUI

struct LocalImage<Content: View, Placeholder: View>: View {
    @EnvironmentObject var persistence: Persistence
    private var handle: ImageAssetObject?
    private let image: (Image) -> Content
    private let placeholder: () -> Placeholder

    init(
        _ object: ImageAssetObject?,
        @ViewBuilder image: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
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
