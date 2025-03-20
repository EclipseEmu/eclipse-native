import SwiftUI

/// CIImage is thread safe.
/// > https://developer.apple.com/documentation/coreimage/cicontext
extension CIImage: @retroactive @unchecked Sendable {}

extension CGImage {
    func averageColor() -> Color? {
        let size = CGSize(width: 40, height: 40)

        let width = Int(size.width)
        let height = Int(size.height)
        let totalPixels = width * height

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        context.draw(self, in: CGRect(origin: .zero, size: size))

        guard let pixelBuffer = context.data else { return nil }
        let pixelBufferPointer = pixelBuffer.bindMemory(to: UInt32.self, capacity: totalPixels)

        var totalRed = 0
        var totalBlue = 0
        var totalGreen = 0

        for offset in 0 ..< totalPixels {
            let pixel = pixelBufferPointer[offset]
            totalRed += Int((pixel >> 16) & 0xFF)
            totalGreen += Int((pixel >> 8) & 0xFF)
            totalBlue += Int(pixel & 0xFF)
        }

        let totalPixelsFloat = CGFloat(totalPixels)
        return Color(
            red: CGFloat(totalRed) / totalPixelsFloat / 255.0,
            green: CGFloat(totalGreen) / totalPixelsFloat / 255.0,
            blue: CGFloat(totalBlue) / totalPixelsFloat / 255.0
        )
    }
}

#if canImport(AppKit)
extension NSImage {
    func averageColor() -> Color? {
        return self.cgImage(forProposedRect: nil, context: nil, hints: nil)?.averageColor()
    }
}

#elseif canImport(UIKit)
extension UIImage {
    func averageColor() -> Color? {
        return cgImage?.averageColor()
    }
}
#endif
