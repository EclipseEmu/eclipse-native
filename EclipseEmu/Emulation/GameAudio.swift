import Foundation
import AVFoundation
import EclipseKit

// FIXME: handle changes in audio output

actor GameAudio {
    enum Failure: Error {
        case failedToGetAudioFormat
        case unknownSampleFormat
    }
    
    // SAFTEY: the ring buffer itself is thread-safe
    nonisolated(unsafe) var ringBuffer: RingBuffer
    weak var core: GameCore?
    let audio = AVAudioEngine()
    var sourceNode: AVAudioSourceNode?
    let inputFormat: AVAudioFormat
    var outputFormat: AVAudioFormat
    var sampleRateRatio: Int
    var running = false

    @usableFromInline
    var volume: Float {
        get {
            return self.audio.mainMixerNode.outputVolume
        }
        set {
            self.audio.mainMixerNode.outputVolume = newValue
        }
    }
    
    public init(core: GameCore) throws {
        self.core = core
        guard let format = core.getAudioFormat() else { throw Failure.failedToGetAudioFormat }
        
        let bytesPerSample = format.commonFormat.bytesPerSample
        guard bytesPerSample != -1 else { throw Failure.unknownSampleFormat }
        
        let ringBufferSize = Int(format.sampleRate * Double(format.channelCount * 2))
        self.inputFormat = format
        self.outputFormat = self.audio.outputNode.outputFormat(forBus: 0)
        self.ringBuffer = RingBuffer(capacity: ringBufferSize, alignment: bytesPerSample)
        self.sampleRateRatio = Int((inputFormat.sampleRate / outputFormat.sampleRate).rounded(.up))
    }
    
    deinit {
        Task {
            await self.stop()
        }
    }
    
    func start() {
        var lastAvailableRead: Int = -1
        let sourceNode = AVAudioSourceNode(format: self.inputFormat) { [inputFormat, ringBuffer, sampleRateRatio] isSilence, timestamp, frameCount, audioBufferList in
            defer { lastAvailableRead = ringBuffer.availableRead() }
            
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = buffers[0].mData else {
                return kAudioFileStreamError_UnspecifiedError
            }
            
            let requested = Int(frameCount * inputFormat.streamDescription.pointee.mBytesPerFrame)
            let availableRead = ringBuffer.availableRead()
            guard availableRead >= requested * sampleRateRatio && availableRead >= lastAvailableRead && availableRead >= requested else {
                return kAudioFileStreamError_DataUnavailable
            }
            
            guard ringBuffer.read(into: UnsafeMutableRawBufferPointer(start: buffer, count: requested)) else {
                return kAudioFileStreamError_DataUnavailable
            }
            
            buffers[0].mDataByteSize = UInt32(requested)
            return noErr
        }
        
        self.audio.attach(sourceNode)
        self.audio.connect(sourceNode, to: self.audio.mainMixerNode, format: self.outputFormat)
        self.audio.connect(self.audio.mainMixerNode, to: self.audio.outputNode, format: self.outputFormat)
        self.volume = 0.01
    }
    
    func stop() {
        audio.stop()
        if let sourceNode {
            self.audio.detach(sourceNode)
        }
        self.sourceNode = nil
    }

    func pause() {
        self.audio.pause()
    }
    
    func resume() {
        do {
            let _ = self.audio.mainMixerNode
            try self.audio.start()
        } catch {
            print("failed to start audio", error)
        }
    }
    
    @inlinable
    nonisolated func write(samples: UnsafeRawPointer, count: Int) -> Bool {
        return self.ringBuffer.write(from: UnsafeRawBufferPointer(start: samples, count: count))
    }
}
