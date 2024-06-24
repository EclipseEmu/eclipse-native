import Foundation
import CoreData

extension Persistence {
    enum ImageSource: Sendable {
        case local(URL)
        case web(URL)
    }

    func prepareImage(from source: ImageSource) async throws -> Files.Path {
        let id = UUID()
        let fileExtension = if case .web(let url) = source {
            url.fileExtension()
        } else {
            "jpeg"
        }

        let destination = Files.Path.image(id, fileExtension)
        switch source {
        case .local(let path):
            try await Files.shared.copy(from: path, to: destination)
        case .web(let url):
            let request = URLRequest(url: url)
            let (tempUrl, _) = try await URLSession.shared.download(for: request)
            try await Files.shared.move(from: tempUrl, to: destination)
        }

        return .image(id, fileExtension)
    }

    func create(image path: Files.Path, in context: NSManagedObjectContext) throws -> ImageAsset {
        guard case .image(let id, let ext) = path else { throw PersistenceError.unwrapFailed }

        let asset = ImageAsset(context: context)
        asset.id = id
        asset.fileExtension = ext
        return asset
    }
}
