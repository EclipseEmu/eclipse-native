import CoreImage
import EclipseKit
import Foundation
import Metal
import QuartzCore
import simd

struct FrameBuffer: ~Copyable {
    let buffer: UnsafeMutableRawPointer
    private let bufferSize: Int
    private let isBufferOwned: Bool

    private let width: Int
    private let height: Int

    private let bytesPerRow: Int
    private let sourceBuffer: MTLBuffer

    init(device: MTLDevice, pixelFormat: MTLPixelFormat, height: Int, width: Int, ptr: UnsafeRawPointer?) throws {
        let bytesPerRow = pixelFormat.bytesPerPixel * width
        let bufferSize = bytesPerRow * height

        self.bytesPerRow = bytesPerRow
        self.width = width
        self.height = height

        guard let sourceBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared) else {
            throw GameFrameBufferRenderer.Failure.failedToMakeSourceBuffer
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
            texture.replace(
                region: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0,
                withBytes: buffer,
                bytesPerRow: bytesPerRow
            )
            return
        }

        sourceBuffer.contents().copyMemory(from: buffer, byteCount: bufferSize)

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

final class GameFrameBufferRenderer {
    enum Failure: Error {
        case failedToGetMetalDevice
        case failedToCreateFullscreenQuad
        case failedToCreatePipelineState
        case failedToCreateTheCommandQueue
        case failedToCreateSamplerState
        case failedToMakeSourceBuffer
    }

    struct Vertex {
        let position: simd_float2
        let textureCoordinates: simd_float2
    }

    private(set) var renderTexture: MTLTexture?
    var useAdaptiveSync: Bool = true
    var frameDuration: Double

    private let device: MTLDevice
    private let frameBuffer: FrameBuffer
    private var commandQueue: MTLCommandQueue
    private var quadBuffer: MTLBuffer
    private var pipelineState: MTLRenderPipelineState
    private var samplerState: MTLSamplerState

    /// NOTE: The core is not stored, it is only used to initialize the frame buffer.
    init(
        with device: MTLDevice,
        width: Int,
        height: Int,
        pixelFormat: MTLPixelFormat,
        frameDuration: Double,
        core: UnsafeMutablePointer<GameCore>
    ) throws {
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            throw Failure.failedToCreateTheCommandQueue
        }
        self.commandQueue = queue

        let vertexArrayObject: [Vertex] = [
            .init(position: simd_float2(1, -1), textureCoordinates: simd_float2(1, 1)),
            .init(position: simd_float2(-1, -1), textureCoordinates: simd_float2(0, 1)),
            .init(position: simd_float2(-1, 1), textureCoordinates: simd_float2(0, 0)),
            .init(position: simd_float2(1, -1), textureCoordinates: simd_float2(1, 1)),
            .init(position: simd_float2(-1, 1), textureCoordinates: simd_float2(0, 0)),
            .init(position: simd_float2(1, 1), textureCoordinates: simd_float2(1, 0))
        ]

        guard let buffer = self.device.makeBuffer(
            bytes: vertexArrayObject,
            length: MemoryLayout<Vertex>.size * vertexArrayObject.count,
            options: [.storageModeShared]
        ) else {
            throw Failure.failedToCreateFullscreenQuad
        }

        self.quadBuffer = buffer

        // create the shader pipeline

        let defaultLibrary = device.makeDefaultLibrary()
        let vertexProgram = defaultLibrary?.makeFunction(name: "framebuffer_vertex_main")
        let fragmentProgram = defaultLibrary?.makeFunction(name: "framebuffer_fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexProgram
        pipelineDescriptor.fragmentFunction = fragmentProgram
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        guard let pipelineState = try? self.device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            throw Failure.failedToCreatePipelineState
        }

        self.pipelineState = pipelineState

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear

        guard let samplerState = self.device.makeSamplerState(descriptor: samplerDescriptor) else {
            throw Failure.failedToCreateSamplerState
        }

        self.samplerState = samplerState
        self.frameDuration = frameDuration

        // setup the frame buffer and setup the texture

        if core.pointee.canSetVideoPointer(core.pointee.data) {
            let buffer = try FrameBuffer(
                device: device,
                pixelFormat: pixelFormat,
                height: height,
                width: width,
                ptr: nil
            )
            _ = core.pointee.getVideoPointer(core.pointee.data, buffer.buffer)
            self.frameBuffer = buffer
        } else {
            let buf = UnsafeMutableRawPointer(mutating: core.pointee.getVideoPointer(core.pointee.data, nil))
            self.frameBuffer = try FrameBuffer(
                device: device,
                pixelFormat: pixelFormat,
                height: height,
                width: width,
                ptr: buf
            )
        }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        self.renderTexture = device.makeTexture(descriptor: textureDescriptor)
    }

    func render(in renderingSurface: CAMetalLayer) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        guard let texture = renderTexture else { return }
        frameBuffer.prepare(with: commandBuffer, texture: texture)

        guard let drawable = renderingSurface.nextDrawable() else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Could not create encoder for metal renderer")
            return
        }

        encoder.setRenderPipelineState(pipelineState)

        encoder.setVertexBuffer(quadBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        commandBuffer.addScheduledHandler { [self] _ in
            if useAdaptiveSync {
#if !targetEnvironment(simulator)
                drawable.present(afterMinimumDuration: self.frameDuration)
#else
                drawable.present()
#endif
            } else {
                drawable.present()
            }
        }

        commandBuffer.commit()
    }

    func screenshot(colorSpace: CGColorSpace) -> CIImage? {
        guard
            let renderTexture,
            let image = CIImage(mtlTexture: renderTexture, options: [.nearestSampling: true, .colorSpace: colorSpace])
        else { return nil }

        return image
            .transformed(by: .identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.size.height))
    }
}
