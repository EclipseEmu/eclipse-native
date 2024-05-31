import Foundation
import AVFoundation

final class GameAudio {
    enum Failure: Error {
        case failedToGetAudioFormat
        case unknownSampleFormat
        case failedToInitializeRingBuffer
    }

    // Unfortunately, AVAudioEngine blocks which causes major issues when used within Swift Concurrency (i.e. deadlocks)
    // so we have to use a DispatchQueue here.
    private let queue = DispatchQueue(label: "dev.magnetar.eclipseemu.queue.audio")
    private var ringBuffer: RingBuffer

    private let inputFormat: AVAudioFormat
    private let engine: AVAudioEngine
    private let playback: AVAudioUnitTimePitch
    private var sourceNode: AVAudioSourceNode?

    private(set) var running = false
    private var lastAvailableRead: Int = -1
    private var hardwareListener: Any?
    private var isUsingDefaultOutput = true

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
        self.inputFormat = format
        self.ringBuffer = RingBuffer(capacity: Int(format.sampleRate * Double(format.channelCount * 2)))

        self.engine = AVAudioEngine()
        playback = AVAudioUnitTimePitch()
        self.engine.attach(self.playback)
        self.engine.connect(self.engine.mainMixerNode, to: self.playback, format: nil)
        self.engine.connect(self.playback, to: self.engine.outputNode, format: nil)

#if os(macOS)
        self.setOutputDevice(0)
#endif
    }

    deinit {
        if let sourceNode {
            engine.detach(sourceNode)
        }
        engine.detach(playback)
        self.stopListeningForHardwareChanges()
    }

    func start() async {
        await withUnsafeContinuation { continuation in
            self.queue.async {
                self.createSourceNode()
                self.engine.prepare()
                self.listenForHardwareChanges()
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
                self._resume()
                continuation.resume()
            }
        }
    }

    private func _resume() {
        self.running = true
        do {
            try self.engine.start()
        } catch {
            print(error.localizedDescription)
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
        self.queue.async {
            self.playback.rate = rate
        }
    }

    @inlinable
    func clear() {
        self.ringBuffer.clear()
    }

    @inlinable
    func write(samples: UnsafeRawPointer, count: Int) -> Int {
        return ringBuffer.write(src: samples, length: count)
    }

    // MARK: Source Node Handling

    private func createSourceNode() {
        if let sourceNode {
            self.engine.detach(sourceNode)
        }

        self.sourceNode = AVAudioSourceNode(format: inputFormat, renderBlock: renderBlock)

        if let sourceNode {
            self.engine.attach(sourceNode)
            self.engine.connect(sourceNode, to: self.engine.mainMixerNode, format: self.inputFormat)
        }
    }

    private func renderBlock(
        isSilence: UnsafeMutablePointer<ObjCBool>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard let buffer = buffers[0].mData else {
            self.lastAvailableRead = ringBuffer.availableRead()
            return kAudioFileStreamError_UnspecifiedError
        }

        let requested = Int(frameCount * self.inputFormat.streamDescription.pointee.mBytesPerFrame)
        let availableRead = ringBuffer.availableRead()
        guard availableRead >= requested && availableRead >= self.lastAvailableRead else {
            self.lastAvailableRead = availableRead
            return kAudioFileStreamError_DataUnavailable
        }

        let amountRead = self.ringBuffer.read(dst: buffer, length: requested)
        guard amountRead > 0 else {
            self.lastAvailableRead = ringBuffer.availableRead()
            return kAudioFileStreamError_DataUnavailable
        }

        buffers[0].mDataByteSize = UInt32(amountRead)
        self.lastAvailableRead = ringBuffer.availableRead()
        return noErr
    }

    // MARK: Output Change Handling

    func listenForHardwareChanges() {
        self.hardwareListener = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: self.engine, queue: .current
        ) { [weak self] _ in
            guard let self else { return }
#if os(macOS)
            self.setOutputDevice(self.isUsingDefaultOutput ? 0 : engine.outputNode.auAudioUnit.deviceID)
#else
            self.engine.stop()

            if let sourceNode {
                self.engine.connect(sourceNode, to: self.engine.mainMixerNode, format: self.inputFormat)
            }

            guard self.running && !self.engine.isRunning else { return }
            self.engine.prepare()
            self._resume()
#endif
        }
    }

    func stopListeningForHardwareChanges() {
        if let hardwareListener {
            NotificationCenter.default.removeObserver(hardwareListener)
            self.hardwareListener = nil
        }
    }

#if os(macOS)
    /// There was a bug, it may still be a thing, where with AirPods the audio engine 
    /// would prepare both input and output. This bug essentially degraded audio to the
    /// phone call quality, which is awful.
    func getDefaultDevice() -> AudioDeviceID {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var defaultDevice: AudioObjectID = 0
        var size = UInt32(MemoryLayout.size(ofValue: defaultDevice))
        let err = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addr,
            0,
            nil,
            &size,
            &defaultDevice
        )

        guard err == noErr && defaultDevice != kAudioDeviceUnknown else { return 0 }
        return defaultDevice
    }

    func setOutputDevice(_ deviceId: AudioDeviceID) {
        self.isUsingDefaultOutput = deviceId == 0

        let id = if deviceId == 0 {
            self.getDefaultDevice()
        } else {
            deviceId
        }

        engine.stop()

        do {
            try engine.outputNode.auAudioUnit.setDeviceID(id)
        } catch {
            print("failed to set the audio output device", error)
        }

        if let sourceNode {
            self.engine.connect(sourceNode, to: self.engine.mainMixerNode, format: self.inputFormat)
        }

        guard self.running && !self.engine.isRunning else { return }
        self.engine.prepare()
        self._resume()
    }
#else
    static func setRequireRinger(requireRinger: Bool) {
        do {
            try AVAudioSession.sharedInstance().setCategory(requireRinger ? .ambient : .playback)
        } catch {
            print("failed to set audio category", error)
        }
    }
#endif
}
