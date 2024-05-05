import Foundation
import AVFoundation

// FIXME: Handle hardware/sample rate changes.
// FIXME: Figure out how to deal with initial audio crackle.
// FIXME: Figure out how to deal with audio being ~0.5 seconds delayed.
// FIXME: Figure out why this randomly crashes.
// FIXME: Figure out why AVAudioEngine deadlocks sometimes.
// FIXME: Figure out why this randomly will blast audio sometimes but not others.

final class GameAudio {
    enum Failure: Error {
        case failedToGetAudioFormat
        case unknownSampleFormat
        case failedToInitializeRingBuffer
    }
    
    // Unfortunately, AVAudioEngine blocks which causes major issues when used within Swift Concurrency (i.e. deadlocks),
    // so we have to use a DispatchQueue here.
    private let queue = DispatchQueue(label: "dev.magnetar.eclipseemu.queue.audio")
    private let ringBuffer: OpaquePointer
    
    private let inputFormat: AVAudioFormat
    private var outputFormat: AVAudioFormat
    private var sampleRateRatio: Int
    
    private let engine: AVAudioEngine
    private let playback: AVAudioUnitTimePitch
    private var sourceNode: AVAudioSourceNode?
    
    private(set) var running = false
    private var lastAvailableRead: UInt64 = 0
    
    @usableFromInline
    var volume: Float {
        get {
            return self.engine.mainMixerNode.outputVolume
        }
        set {
            self.queue.async {
                self.engine.mainMixerNode.outputVolume = newValue
            }
        }
    }

    init(format: AVAudioFormat?) throws {
        guard let format else { throw Failure.failedToGetAudioFormat }
        
        let bytesPerSample = format.commonFormat.bytesPerSample
        guard bytesPerSample != -1 else { throw Failure.unknownSampleFormat }
        
        let ringBufferSize = Int(format.sampleRate * Double(format.channelCount * 2))
        self.inputFormat = format
        
        guard let ringBuffer = ring_buffer_init(UInt64(ringBufferSize)) else {
            throw Failure.failedToInitializeRingBuffer
        }
        self.ringBuffer = ringBuffer
        
        self.engine = AVAudioEngine()
        playback = AVAudioUnitTimePitch()
        self.engine.attach(self.playback)

        outputFormat = engine.outputNode.outputFormat(forBus: 0)
        sampleRateRatio = Int((inputFormat.sampleRate / outputFormat.sampleRate).rounded(.up))
        
        #if os(macOS)
        self.setOutputDeviceFor(self.engine)
        #endif
    }
    
    deinit {
        if let sourceNode {
            engine.detach(sourceNode)
        }
        engine.detach(playback)
        ring_buffer_deinit(ringBuffer)
    }
    
    #if os(iOS)
    static func setRequireRinger(requireRinger: Bool) -> Void {
        do {
            try AVAudioSession.sharedInstance().setCategory(requireRinger ? .ambient : .playback)
        } catch {
            print("failed to set audio category", error)
        }
    }
    #endif

    func start() async {
        await withUnsafeContinuation { continuation in
            self.queue.async {
                self.createSourceNode()
                
                self.engine.attach(self.sourceNode!)
                
                self.engine.connect(self.sourceNode!, to: self.engine.mainMixerNode, format: self.inputFormat)
                self.engine.connect(self.engine.mainMixerNode, to: self.playback, format: self.outputFormat)
                self.engine.connect(self.playback, to: self.engine.outputNode, format: self.outputFormat)
                
                self.engine.prepare()
                continuation.resume()
            }
        }
    }
    
    func stop() async {
        await withUnsafeContinuation { continuation in
            self.queue.async {
                self.running = false
                if let sourceNode = self.sourceNode {
                    self.engine.detach(sourceNode)
                    self.sourceNode = nil
                }
                continuation.resume()
            }
        }
    }
    
    func resume() async {
        await withUnsafeContinuation { continuation in
            self.queue.async {
                self.running = true
                do {
                    try self.engine.start()
                } catch {
                    print(error.localizedDescription)
                }
                continuation.resume()
            }
        }
    }
    
    func pause() async {
        await withUnsafeContinuation { continuation in
            self.queue.async {
                self.engine.pause()
                self.running = false
                continuation.resume()
            }
        }
    }
    
    func setRate(rate: Float) {
        self.playback.rate = rate
    }
    
    @inlinable
    func clear() {
        ring_buffer_clear(self.ringBuffer)
    }
    
    @inlinable
    func write(samples: UnsafeRawPointer, count: UInt64) -> UInt64 {
        return ring_buffer_write(self.ringBuffer, samples, UInt64(count))
    }

    // MARK: Source Node Handling
    
    private func createSourceNode() {
        if let sourceNode {
            self.engine.detach(sourceNode)
        }
        
        sourceNode = AVAudioSourceNode(format: inputFormat, renderBlock: renderBlock)
    }
    
    private func renderBlock(
        isSilence: UnsafeMutablePointer<ObjCBool>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        defer { self.lastAvailableRead = ring_buffer_available_read(self.ringBuffer) }
        
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard let buffer = buffers[0].mData else {
            return kAudioFileStreamError_UnspecifiedError
        }
        
        let requested = Int(frameCount * self.inputFormat.streamDescription.pointee.mBytesPerFrame)
        let availableRead = ring_buffer_available_read(self.ringBuffer)
        guard
            availableRead >= requested * self.sampleRateRatio,
            availableRead >= requested,
            availableRead >= self.lastAvailableRead
        else {
            return kAudioFileStreamError_DataUnavailable
        }
        
        let amountRead = ring_buffer_read(self.ringBuffer, buffer, UInt64(requested));
        guard amountRead > 0 else {
            return kAudioFileStreamError_DataUnavailable
        }
        
        buffers[0].mDataByteSize = UInt32(amountRead)
        return noErr
    }
    
    // MARK: Output & Change Handling
    
    #if os(macOS)
    func setOutputDeviceFor(_ engine: AVAudioEngine) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)

        var deviceID: AudioObjectID = 0
        var size = UInt32(MemoryLayout.size(ofValue: deviceID))
        let err = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addr,
            0,
            nil,
            &size,
            &deviceID)

        if (noErr == err && kAudioDeviceUnknown != deviceID) {
            do {
                try engine.outputNode.auAudioUnit.setDeviceID(deviceID)
                self.outputFormat = engine.outputNode.outputFormat(forBus: 0)
                self.sampleRateRatio = Int((inputFormat.sampleRate / outputFormat.sampleRate).rounded(.up))
            } catch {
                print(error)
                return false
            }
            return true
        } else {
            print("ERROR: couldn't get default output device, ID = \(deviceID), err = \(err)")
            return false
        }
    }
    #endif
}
