import Foundation
import Metal

class FrameBuffer {
    let device: MTLDevice
    public let pixelFormat: MTLPixelFormat
    let bytesPerPixel: Int
    let width: Int
    let height: Int

    let bytesPerRow: Int
    let sourceBuffer: MTLBuffer
    
    let buffer: UnsafeMutableRawPointer
    let bufferSize: Int
    let isBufferOwned: Bool
    
    enum Failure: Error {
        case failedToMakeSourceBuffer
    }
    
    init(device: MTLDevice, pixelFormat: MTLPixelFormat, height: Int, width: Int, ptr: UnsafeRawPointer?) throws {
        let bytesPerRow = pixelFormat.bytesPerPixel * width
        let bufferSize = bytesPerRow * height
        
        self.device = device
        self.pixelFormat = pixelFormat
        self.bytesPerPixel = pixelFormat.bytesPerPixel
        self.bytesPerRow = bytesPerRow
        self.width = width
        self.height = height

        guard let sourceBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared) else {
            throw Failure.failedToMakeSourceBuffer
        }
        self.sourceBuffer = sourceBuffer
        
        self.bufferSize = bufferSize
        self.isBufferOwned = ptr == nil
        if let ptr {
            self.buffer = UnsafeMutableRawPointer(mutating: ptr)
        } else {
            self.buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 1)
        }
    }
    
    deinit {
        if self.isBufferOwned {
            self.buffer.deallocate()
        }
    }
    
    func prepare(with commandBuffer: MTLCommandBuffer, texture: MTLTexture) {
        if texture.storageMode != .private {
            texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: buffer, bytesPerRow: bytesPerRow)
            return
        }
        
        self.sourceBuffer.contents().copyMemory(from: buffer, byteCount: self.bufferSize)
        
        guard let encoder = commandBuffer.makeBlitCommandEncoder() else { return }
        let len = sourceBuffer.length
        encoder.copy(
            from: sourceBuffer,
            sourceOffset: 0,
            sourceBytesPerRow: bytesPerRow,
            sourceBytesPerImage: len,
            sourceSize: MTLSize(width: width, height: height, depth: 1),
            to: texture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: .init()
        )
        encoder.endEncoding()
    }
}
