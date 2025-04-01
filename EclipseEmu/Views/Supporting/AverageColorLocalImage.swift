import SwiftUI

/// A view that loads an image asynchronously and also gets its average color.
struct AverageColorLocalImage<I: View, P: View>: View {
    @State private var task: Task<Void, Never>?

    @EnvironmentObject var persistence: Persistence
    private var handle: ImageAsset?
    private let image: (Image) -> I
    private let placeholder: () -> P

    @Binding private var averageColor: Color?
    @State private var state: AsyncImagePhase = .empty

    init(
        _ object: ImageAsset?,
        color: Binding<Color?>,
        @ViewBuilder image: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) {
        self.handle = object
        self.image = image
        self.placeholder = placeholder
        self._averageColor = color
    }

    var body: some View {
        Group {
            switch state {
            case .success(let image):
                self.image(image)
            case .failure:
                Color.gray
            default:
                placeholder()
            }
        }
        .task(id: self.handle?.id) {
            self.load()
        }
        .onDisappear {
            self.cancel()
        }
    }

    func load() {
        guard let url = persistence.files.url(path: handle?.path) else { return }

        self.task = Task<Void, Never>.detached(priority: .medium) {
            await MainActor.run {
                self.state = .empty
            }
            do {
                try Task.checkCancellation()
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()

#if os(macOS)
                guard let imageView = NSImage(data: data) else { return }
                let image = Image(nsImage: imageView)
#else
                guard let imageView = UIImage(data: data) else { return }
                let image = Image(uiImage: imageView)
#endif
                let color = imageView.averageColor()
                await MainActor.run {
                    self.state = .success(image)
                    self.averageColor = color
                }
            } catch {
                await MainActor.run {
                    self.state = .failure(error)
                }
            }
        }
    }

    func cancel() {
        self.task?.cancel()
    }
}
