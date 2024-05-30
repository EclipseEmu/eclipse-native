import Foundation
import CoreImage
import QuartzCore

enum ImageAssetManager {
    static func create(from ciImage: CIImage, in persistence: PersistenceCoordinator, save: Bool = true) throws -> ImageAsset {
        let asset = ImageAsset(context: persistence.context)
        asset.id = UUID()
        asset.fileExtension = "jpeg"
        
        let context = CIContext()
        try context.writeJPEGRepresentation(
            of: ciImage,
            to: asset.path(in: persistence),
            colorSpace: ciImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        )
        
        if save {
            persistence.save()
        }
        
        return asset
    }
    
    static func create(remote: URL, in persistence: PersistenceCoordinator, save: Bool = true) async throws -> ImageAsset {
        let request = URLRequest(url: remote)
        let (tempUrl, _) = try await URLSession.shared.download(for: request)
        
        let id = UUID()
        let fileExtension = remote.fileExtension()
        
        let destUrl = persistence.getPath(name: id.uuidString, fileExtension: fileExtension, base: persistence.imageDirectory)
        try await withUnsafeThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    if FileManager.default.fileExists(atPath: destUrl.path) {
                        try FileManager.default.removeItem(at: destUrl)
                    }
                    try FileManager.default.moveItem(at: tempUrl, to: destUrl)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        
        let asset = ImageAsset(context: persistence.context)
        asset.id = id
        asset.fileExtension = fileExtension
        
        if save {
            persistence.save()
        }
        
        return asset
    }
}
