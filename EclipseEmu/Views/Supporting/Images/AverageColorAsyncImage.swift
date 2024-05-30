import SwiftUI

/// A view that loads an image asynchronously and also gets its average color.
struct AverageColorAsyncImage<Content: View>: View {
    @Environment(\.persistenceCoordinator) private var persistence
    @State private var task: Task<Void, Never>?

    private var url: URL?
    @Binding private var averageColor: Color?
    @State private var state: AsyncImagePhase = .empty
    let handlePhase: (AsyncImagePhase) -> Content

    init(
        url: URL?,
        averageColor: Binding<Color?>,
        @ViewBuilder handlePhase: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self._averageColor = averageColor
        self.handlePhase = handlePhase
    }

    var body: some View {
        Group {
            handlePhase(state)
        }
        .task(id: url) {
            self.load()
        }
        .onDisappear {
            self.cancel()
        }
    }

    func load() {
        guard let url else { return }

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

#Preview {
    struct PreviewView: View {
        @State var color: Color?

        var body: some View {
            VStack {
                AverageColorAsyncImage(url: URL(string: "https://picsum.photos/200"), averageColor: $color) { imagePhase in
                    switch imagePhase {
                    case .empty:
                        ProgressView()
                    case .failure(_):
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    case .success(let image):
                        image.resizable()
                    @unknown default:
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .aspectRatio(1.0, contentMode: .fill)

                (color ?? .black)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .brightness(-0.15)
            }
        }
    }

    return PreviewView()
}
