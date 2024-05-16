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
        persistence.save()
        
        return asset
    }
}
