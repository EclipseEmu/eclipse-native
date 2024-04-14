import Foundation
import Metal
import QuartzCore
import simd
import EclipseKit

final class GameRenderer2D: GameRenderer {
    enum Failure: Error {
        case failedToGetMetalDevice
        case failedToCreateFullscreenQuad
        case failedToCreatePipelineState
        case failedToCreateTheCommandQueue
        case failedToCreateSamplerState
    }
    
    struct Vertex {
        let position: vector_float2
        let textureCoordinates: vector_float2
    }
    
    let core: GameCore
    private(set) var renderTexture: MTLTexture?
    var useAdaptiveSync: Bool = true
    var desiredFrameRate: Double
    
    private let pixelFormat: MTLPixelFormat
    private let device: MTLDevice
    private var frameBuffer: FrameBuffer?
    private var commandQueue: MTLCommandQueue
    private var quadBuffer: MTLBuffer
    private var pipelineState: MTLRenderPipelineState
    private var samplerState: MTLSamplerState

    init(with device: MTLDevice, pixelFormat: MTLPixelFormat, core: GameCore, desiredFrameRate: Double) throws {
        self.device = device
        guard let queue = device.makeCommandQueue() else {
            throw Failure.failedToCreateTheCommandQueue
        }
        self.commandQueue = queue
        
        self.core = core
        self.pixelFormat = pixelFormat
        
        let vertexArrayObject: [Vertex] = [
            .init(position: vector_float2(1, -1), textureCoordinates: vector_float2(1, 1)),
            .init(position: vector_float2(-1,  -1), textureCoordinates: vector_float2(0, 1)),
            .init(position: vector_float2(-1, 1), textureCoordinates: vector_float2(0, 0)),
            .init(position: vector_float2(1, -1), textureCoordinates: vector_float2(1, 1)),
            .init(position: vector_float2(-1, 1), textureCoordinates: vector_float2(0, 0)),
            .init(position: vector_float2(1, 1), textureCoordinates: vector_float2(1, 0))
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
        self.desiredFrameRate = desiredFrameRate
    }
    
    func update() throws {
        let width = core.getVideoWidth()
        let height = core.getVideoHeight()
        
        if frameBuffer == nil {
            if core.canSetVideoBufferPointer() {
                let buffer = try FrameBuffer(device: device, pixelFormat: pixelFormat, height: height, width: width, ptr: nil)
                let _ = core.getVideoBuffer(setPointer: buffer.buffer)
                self.frameBuffer = buffer
            } else {
                let buf = UnsafeMutableRawPointer(mutating: core.getVideoBuffer(setPointer: nil))
                frameBuffer = try FrameBuffer(device: device, pixelFormat: pixelFormat, height: height, width: width, ptr: buf)
            }
        }
        
        let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: pixelFormat, width: width, height: height, mipmapped: false)
        td.storageMode = .private
        td.usage = [.shaderRead, .shaderWrite]
        renderTexture = device.makeTexture(descriptor: td)
    }
    
    func render(in renderingSurface: CAMetalLayer) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        guard let texture = renderTexture else { return }
        self.frameBuffer?.prepare(with: commandBuffer, texture: texture)
        
        guard let drawable = renderingSurface.nextDrawable() else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1.0)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Could not create encoder for metal renderer")
            return
        }

        encoder.setRenderPipelineState(self.pipelineState)

        encoder.setVertexBuffer(self.quadBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.setFragmentSamplerState(self.samplerState, index: 0)

        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        encoder.endEncoding()

        if useAdaptiveSync {
            commandBuffer.present(drawable, afterMinimumDuration: 1 / self.desiredFrameRate)
        } else {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }
}
