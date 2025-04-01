import AVFoundation
import Foundation
import OSLog

enum GameAudioFailure: Error {
    case getAudioFormat
    case unknownSampleFormat
    case initializeRingBuffer
}

extension AVAudioFormat: @unchecked @retroactive Sendable {}

final actor GameAudio {
    private let executor: BlockingSerialExecutor
    nonisolated let unownedExecutor: UnownedSerialExecutor

    private(set) var running = false

    private let engine: AVAudioEngine
    private let playback: AVAudioUnitTimePitch
    private var sourceNode: AVAudioSourceNode?
    private nonisolated let inputFormat: AVAudioFormat

    // SAFETY: The ring buffer is safe for concurrency.
    private nonisolated(unsafe) var ringBuffer: RingBuffer
    // SAFETY: this is only read from the audio callback.
    private nonisolated(unsafe) var lastAvailableRead: Int = -1

    private var hardwareListener: Task<Void, Never>?
    #if os(macOS)
    private var isUsingDefaultOutput = true
    #endif

    func setVolume(to newValue: Float) {
        self.engine.mainMixerNode.outputVolume = newValue
    }

    init(format: AVAudioFormat) throws(GameAudioFailure) {
        let queue = DispatchQueue(label: "dev.magnetar.eclipseemu.queue.audio")
        self.executor = BlockingSerialExecutor(queue: queue)
        self.unownedExecutor = executor.asUnownedSerialExecutor()

        let bytesPerSample = format.commonFormat.bytesPerSample
        guard bytesPerSample != -1 else { throw .unknownSampleFormat }
        self.inputFormat = format
        self.ringBuffer = RingBuffer(capacity: Int(format.sampleRate * Double(format.channelCount * 2)))

        self.engine = AVAudioEngine()
        self.playback = AVAudioUnitTimePitch()
        self.engine.attach(self.playback)
        self.engine.connect(self.engine.mainMixerNode, to: self.playback, format: nil)
        self.engine.connect(self.playback, to: self.engine.outputNode, format: nil)

#if os(macOS)
        Task {
            await self.setOutputDevice(0)
        }
#endif
    }

    deinit {
        // FIXME: we probably don't need this.
        //        if let sourceNode {
        //            engine.detach(sourceNode)
        //        }
        //        engine.detach(playback)
    }

    func start() {
        self.createSourceNode()
        self.engine.prepare()
        self.listenForHardwareChanges()
    }

    func stop() {
        self.running = false
        if let sourceNode = self.sourceNode {
            self.engine.detach(sourceNode)
            self.sourceNode = nil
        }
        self.hardwareListener?.cancel()
    }

    func resume() {
        self.running = true
        do {
            try self.engine.start()
        } catch {
            Logger.emulation.error("audio renderer - failed to start engine: \(error.localizedDescription)")
        }
    }

    func pause() {
        self.engine.pause()
        self.running = false
    }

    func setRate(rate: Float) {
        self.playback.rate = rate
    }

    @inlinable
    func clear() {
        self.ringBuffer.clear()
    }

    @inlinable
    nonisolated func write(samples: UnsafeRawPointer, count: Int) -> Int {
        return self.ringBuffer.write(src: samples, length: count)
    }

    // MARK: Source Node Handling

    private func createSourceNode() {
        if let sourceNode {
            self.engine.detach(sourceNode)
        }

        self.sourceNode = AVAudioSourceNode(format: self.inputFormat, renderBlock: self.renderBlock)

        if let sourceNode {
            self.engine.attach(sourceNode)
            self.engine.connect(sourceNode, to: self.engine.mainMixerNode, format: self.inputFormat)
        }
    }

    private nonisolated func renderBlock(
        isSilence: UnsafeMutablePointer<ObjCBool>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        frameCount: AVAudioFrameCount,
        audioBufferList: UnsafeMutablePointer<AudioBufferList>
    ) -> OSStatus {
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard let buffer = buffers[0].mData else {
            self.lastAvailableRead = self.ringBuffer.availableRead()
            return kAudioFileStreamError_UnspecifiedError
        }

        let requested = Int(frameCount * self.inputFormat.streamDescription.pointee.mBytesPerFrame)
        let availableRead = self.ringBuffer.availableRead()
        guard availableRead >= requested && availableRead >= self.lastAvailableRead else {
            self.lastAvailableRead = availableRead
            return kAudioFileStreamError_DataUnavailable
        }

        let amountRead = self.ringBuffer.read(dst: buffer, length: requested)
        guard amountRead > 0 else {
            self.lastAvailableRead = self.ringBuffer.availableRead()
            return kAudioFileStreamError_DataUnavailable
        }

        buffers[0].mDataByteSize = UInt32(amountRead)
        self.lastAvailableRead = self.ringBuffer.availableRead()
        return noErr
    }

    // MARK: Output Change Handling

    func hardwareChanged() {
#if os(macOS)
        self.setOutputDevice(self.isUsingDefaultOutput ? 0 : self.engine.outputNode.auAudioUnit.deviceID)
#else
        self.engine.stop()

        if let sourceNode {
            self.engine.connect(sourceNode, to: self.engine.mainMixerNode, format: self.inputFormat)
        }

        guard self.running, !self.engine.isRunning else { return }
        self.engine.prepare()
        self.resume()
#endif
    }

    private func listenForHardwareChanges() {
        self.hardwareListener = Task {
            let stream = NotificationCenter.default.notifications(named: .AVAudioEngineConfigurationChange).map { _ in }
            for await _ in stream {
                guard !Task.isCancelled else { return }
                self.hardwareChanged()
            }
        }
    }

    private func stopListeningForHardwareChanges() {
        hardwareListener?.cancel()
        hardwareListener = nil
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

        self.engine.stop()

        do {
            try self.engine.outputNode.auAudioUnit.setDeviceID(id)
        } catch {
            Logger.emulation.warning("audio renderer - failed to set the audio output device: \(error)")
        }

        if let sourceNode {
            self.engine.connect(sourceNode, to: self.engine.mainMixerNode, format: self.inputFormat)
        }

        guard self.running, !self.engine.isRunning else { return }
        self.engine.prepare()
        self.resume()
    }
#else
    static func setRequireRinger(requireRinger: Bool) {
        do {
            try AVAudioSession.sharedInstance().setCategory(requireRinger ? .ambient : .playback)
        } catch {
            Logger.emulation.warning("audio renderer - failed to set audio category: \(error)")
        }
    }
#endif
}
