import Metal

extension MTLPixelFormat {
    var bytesPerPixel: Int {
        switch self {
        case .bgra8Unorm, .rgba8Unorm:
            return 4
        default:
            preconditionFailure("unsupported pixel format")
        }
    }
}
