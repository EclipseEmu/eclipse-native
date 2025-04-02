import MetalKit
import OSLog

enum FrameBufferRendererError: Error {
    case makeTextureBuffer
    case makeShaderLibrary
    case makePipelineState(any Error)
    case makeFullscreenTexture
    case makeSamplerState
}

private struct DrawingTarget: ~Copyable, @unchecked Sendable {
    let drawable: any MTLDrawable
    let texture: any MTLTexture

    init(drawable: any CAMetalDrawable) {
        self.drawable = drawable
        self.texture = drawable.texture
    }
}

final actor FrameBufferRenderer {
    let context: GlobalMetalContext
    private nonisolated(unsafe) weak var surface: CAMetalLayer?

    nonisolated let width: Int
    nonisolated let height: Int
    nonisolated let pixelFormat: MTLPixelFormat
    nonisolated let bytesPerRow: Int
    nonisolated let bufferSize: Int

    private nonisolated(unsafe) let buffer: UnsafeMutablePointer<UInt8>
    private let isBufferOwned: Bool

    private let textureBuffer: any MTLBuffer
    private let fullscreenTexture: any MTLTexture
    private let pipelineState: any MTLRenderPipelineState
    private let samplerState: any MTLSamplerState

    init(
        context: GlobalMetalContext,
        width: Int,
        height: Int,
        pixelFormat: MTLPixelFormat,
        pointer: consuming UnsafeOwned<UnsafeRawPointer>?
    ) async throws(FrameBufferRendererError) {
        let bytesPerRow = pixelFormat.bytesPerPixel * width
        let bufferSize = bytesPerRow * height

        guard let shaderLibrary = await context.shader()?.value else {
            throw .makeShaderLibrary
        }

        let vertexShader = shaderLibrary.makeFunction(name: "framebuffer_vertex_main")
        let fragmentShader = shaderLibrary.makeFunction(name: "framebuffer_fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexShader
        pipelineDescriptor.fragmentFunction = fragmentShader
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat

        let pipelineState: any MTLRenderPipelineState
        do {
            pipelineState = try await context.makePipelineState(descriptor: pipelineDescriptor).value
        } catch {
            throw .makePipelineState(error)
        }

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear

        guard let samplerState = await context.makeSamplerState(descriptor: samplerDescriptor)?.value else {
            throw .makeSamplerState
        }

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.storageMode = .private
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        guard let fullscreenTexture = await context.makeTexture(descriptor: textureDescriptor)?.value else {
            throw .makeFullscreenTexture
        }

        guard let textureBuffer = await context.allocate(length: bufferSize, options: .storageModeShared)?.value else {
            throw .makeTextureBuffer
        }

        self.context = context

        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
        self.bufferSize = bufferSize
        self.bytesPerRow = bytesPerRow

        self.textureBuffer = textureBuffer
        self.fullscreenTexture = fullscreenTexture
        self.pipelineState = pipelineState
        self.samplerState = samplerState

        self.isBufferOwned = pointer == nil
        self.buffer = if let pointer {
            UnsafeMutableRawPointer(mutating: pointer.value).assumingMemoryBound(to: UInt8.self)
        } else {
            UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 1).assumingMemoryBound(to: UInt8.self)
        }
    }

    deinit {
        if isBufferOwned {
            buffer.deallocate()
        }
    }

    @inlinable
    func getBufferPointer() -> UnsafeSendable<UnsafeMutablePointer<UInt8>> {
        .init(buffer)
    }

    @MainActor
    func attach(surface: CAMetalLayer) {
        surface.device = context.device
        surface.drawableSize = CGSize(width: width, height: height)
        surface.contentsScale = 1.0
        surface.pixelFormat = pixelFormat
        surface.needsDisplayOnBoundsChange = true
        surface.framebufferOnly = true
        surface.isOpaque = true
        surface.presentsWithTransaction = true
        self.surface = surface
    }

    private func nextDrawingTarget() -> DrawingTarget? {
        guard let drawable = surface?.nextDrawable() else {
            return nil
        }
        return DrawingTarget(drawable: drawable)
    }

    private func prepare(with commandBuffer: any MTLCommandBuffer, texture: any MTLTexture) {
        switch texture.storageMode {
        case .private:
            textureBuffer.contents().copyMemory(from: buffer, byteCount: bufferSize)
            if let encoder = commandBuffer.makeBlitCommandEncoder() {
                encoder.copy(
                    from: textureBuffer,
                    sourceOffset: 0,
                    sourceBytesPerRow: bytesPerRow,
                    sourceBytesPerImage: textureBuffer.length,
                    sourceSize: MTLSize(width: width, height: height, depth: 1),
                    to: texture,
                    destinationSlice: 0,
                    destinationLevel: 0,
                    destinationOrigin: .init()
                )
                encoder.endEncoding()
            }
        default:
            texture.replace(
                region: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0,
                withBytes: buffer,
                bytesPerRow: bytesPerRow
            )
        }
    }

    func render() {
        guard let target = self.nextDrawingTarget() else {
            Logger.emulation.warning("framebuffer renderer - failed to get drawable")
            return
        }
        guard let commandBuffer = context.makeCommandBuffer()?.value else {
            Logger.emulation.warning("framebuffer renderer - failed to make command buffer")
            return
        }

        prepare(with: commandBuffer, texture: fullscreenTexture)

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = target.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            Logger.emulation.warning("framebuffer renderer - failed to create encoder")
            return
        }

        encoder.setRenderPipelineState(pipelineState)

        encoder.setFragmentTexture(fullscreenTexture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        commandBuffer.addScheduledHandler { commandBuffer in
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            target.drawable.present()
            CATransaction.commit()
        }

        commandBuffer.commit()
    }

    func screenshot() -> CIImage? {
        let colorSpace = surface?.colorspace ?? CGColorSpaceCreateDeviceRGB()

        guard let image = CIImage(
            mtlTexture: fullscreenTexture,
            options: [.nearestSampling: true, .colorSpace: colorSpace]
        ) else { return nil }

        return image.transformed(by: .identity.scaledBy(x: 1, y: -1).translatedBy(x: 0, y: image.extent.size.height))
    }
}
