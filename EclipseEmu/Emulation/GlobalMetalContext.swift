import MetalKit

enum GlobalGraphicsContextError: Error {
    case getDevice
    case makeCommandQueue
    case noShaderSource
}

struct UnsafeOwned<T>: ~Copyable, @unchecked Sendable {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}

struct UnsafeSendable<T>: @unchecked Sendable {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}

@MainActor
struct GlobalMetalContext {
    let device: any MTLDevice
    nonisolated let commandQueue: UnsafeSendable<any MTLCommandQueue>

    init() throws(GlobalGraphicsContextError) {
        guard let device = MTLCreateSystemDefaultDevice() else {
            throw .getDevice
        }

        guard let commandQueue = device.makeCommandQueue() else {
            throw .makeCommandQueue
        }

        self.device = device
        self.commandQueue = .init(commandQueue)
    }

    @inlinable
    func shader() -> sending UnsafeOwned<any MTLLibrary>? {
        guard let shader = device.makeDefaultLibrary() else {
            return nil
        }
        return UnsafeOwned(shader)
    }

    @inlinable
    func shader(url path: URL) throws -> sending UnsafeOwned<any MTLLibrary> {
        return try UnsafeOwned(device.makeLibrary(URL: path))
    }

    @inlinable
    func shader(source rawSource: String) throws -> sending UnsafeOwned<any MTLLibrary> {
        return try UnsafeOwned(device.makeLibrary(source: rawSource, options: nil))
    }

    @inlinable
    func makePipelineState(descriptor: MTLRenderPipelineDescriptor) throws -> sending UnsafeOwned<any MTLRenderPipelineState> {
        UnsafeOwned(try device.makeRenderPipelineState(descriptor: descriptor))
    }

    @inlinable
    func makeSamplerState(descriptor: MTLSamplerDescriptor) -> sending UnsafeOwned<any MTLSamplerState>? {
        guard let samplerState = device.makeSamplerState(descriptor: descriptor) else {
            return nil
        }
        return UnsafeOwned(samplerState)
    }

    @inlinable
    func makeTexture(descriptor: MTLTextureDescriptor) -> sending UnsafeOwned<any MTLTexture>? {
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        return UnsafeOwned(texture)
    }

    @inlinable
    func allocate(bytes: UnsafeRawPointer, length: Int, options: MTLResourceOptions) -> sending UnsafeOwned<any MTLBuffer>? {
        guard let buffer = device.makeBuffer(bytes: bytes, length: length, options: options) else {
            return nil
        }
        return UnsafeOwned(buffer)
    }

    @inlinable
    func allocate(length: Int, options: MTLResourceOptions) -> sending UnsafeOwned<any MTLBuffer>? {
        guard let buffer = device.makeBuffer(length: length, options: .storageModeShared) else {
            return nil
        }
        return UnsafeOwned(buffer)
    }

    @inlinable
    nonisolated func makeCommandBuffer() -> sending UnsafeOwned<any MTLCommandBuffer>? {
        guard let buffer = self.commandQueue.value.makeCommandBuffer() else {
            return nil
        }
        return UnsafeOwned(buffer)
    }
}
