import Foundation
import AVFoundation

// FIXME: handle changes in audio output

actor GameAudio {
    enum Failure: Error {
        case failedToGetAudioFormat
        case unknownSampleFormat
        case failedToInitializeRingBuffer
    }
    
    let audio = AVAudioEngine()
    var running = false
    
    private nonisolated(unsafe) var ringBuffer: OpaquePointer
    private var sourceNode: AVAudioSourceNode?
    private let inputFormat: AVAudioFormat
    private var outputFormat: AVAudioFormat
    private var sampleRateRatio: Int
    private var hardwareObserver: Any?
    
    @usableFromInline
    var volume: Float {
        get {
            return self.audio.mainMixerNode.outputVolume
        }
        set {
            self.audio.mainMixerNode.outputVolume = newValue
        }
    }
    
    public init(format: AVAudioFormat?) throws {
        guard let format else { throw Failure.failedToGetAudioFormat }
        
        let bytesPerSample = format.commonFormat.bytesPerSample
        guard bytesPerSample != -1 else { throw Failure.unknownSampleFormat }
        
        let ringBufferSize = Int(format.sampleRate * Double(format.channelCount * 2))
        self.inputFormat = format
        
        guard let ringBuffer = ring_buffer_init(UInt64(ringBufferSize)) else {
            throw Failure.failedToInitializeRingBuffer
        }
        self.ringBuffer = ringBuffer
        
        self.outputFormat = self.audio.outputNode.outputFormat(forBus: 0)
        self.sampleRateRatio = Int((inputFormat.sampleRate / outputFormat.sampleRate).rounded(.up))
    }
    
    deinit {
        Task {
            await self.stop()
            await self.removeListeners()
            ring_buffer_deinit(self.ringBuffer)
        }
    }
    
    func start() {
        if !self.running {
            self.addListeners()
        }
        
        var lastAvailableRead: UInt64? = nil
        let sourceNode = AVAudioSourceNode(format: self.inputFormat) { [inputFormat, sampleRateRatio] isSilence, timestamp, frameCount, audioBufferList in
            defer { lastAvailableRead = ring_buffer_available_read(self.ringBuffer) }
            
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let buffer = buffers[0].mData else {
                return kAudioFileStreamError_UnspecifiedError
            }
            
            let requested = Int(frameCount * inputFormat.streamDescription.pointee.mBytesPerFrame)
            let availableRead = ring_buffer_available_read(self.ringBuffer)
            guard 
                availableRead >= requested * sampleRateRatio,
                availableRead >= requested,
                let lastAvailableRead,
                availableRead >= lastAvailableRead
            else {
                return kAudioFileStreamError_DataUnavailable
            }
            
            let amountRead = ring_buffer_read(self.ringBuffer, buffer, UInt64(requested));
            guard amountRead != 0 else {
                return kAudioFileStreamError_DataUnavailable
            }
            
            buffers[0].mDataByteSize = UInt32(amountRead)
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
        self.running = false
    }

    func pause() {
        self.audio.pause()
        self.running = false
    }
    
    func resume() {
        do {
            let _ = self.audio.mainMixerNode
            try self.audio.start()
            self.running = true
        } catch {
            print("failed to start audio", error)
        }
    }
    
    func addListeners() {
        self.hardwareObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: self.audio, queue: .main) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.handleHardwareChange()
            }
        }
    }
    
    func removeListeners() {
        guard let observer = self.hardwareObserver else { return }
        NotificationCenter.default.removeObserver(observer)
    }
    
    func handleHardwareChange() {
        self.stop()
        
        self.outputFormat = self.audio.outputNode.outputFormat(forBus: 0)
        self.sampleRateRatio = Int((self.inputFormat.sampleRate / self.outputFormat.sampleRate).rounded(.up))
        
        self.start()
        self.audio.prepare()
        if self.running && !self.audio.isRunning {
            self.resume()
        }
    }
    
    func clear() -> Void {
        ring_buffer_clear(self.ringBuffer)
    }
    
    #if os(iOS)
    nonisolated func setRequireRinger(requireRinger: Bool) -> Void {
        do {
            if requireRinger {
                try AVAudioSession.sharedInstance().setCategory(.playback)
            } else {
                try AVAudioSession.sharedInstance().setCategory(.ambient)
            }
        } catch {
            print("failed to set audio category", error)
        }
    }
    #endif

    /// NOTE: this
    @inlinable
    nonisolated func write(samples: UnsafeRawPointer, count: UInt64) -> UInt64 {
        return ring_buffer_write(self.ringBuffer, samples, UInt64(count))
    }
}
