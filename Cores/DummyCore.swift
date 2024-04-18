import Foundation
import SwiftUI
import Metal
import EclipseKit
import AVFoundation

final class DummyCore: GameCore {
    var delegate: GameCoreDelegate!
    
    var id: String = "dev.magnetar.dummycore"
    var name: String = "Dummy Core"
    
    var audioSampleBuffer: UnsafeMutableBufferPointer<Int16>!
    var videoBuffer: UnsafeRawPointer!
    
    func setup(system: GameSystem) {
        audioSampleBuffer = .allocate(capacity: 4096)
    }
    
    func takedown() {}
    
    func getDesiredFrameRate() -> Double {
        return 30.0
    }
    
    func getVideoPixelFormat() -> MTLPixelFormat {
        return .bgra8Unorm
    }
    
    func getVideoRenderingType() -> GameCoreRenderFormat {
        return .frameBuffer
    }
    
    func getVideoWidth() -> Int {
        return 160
    }
    
    func getVideoHeight() -> Int {
        return 144
    }
    
    func canSetVideoBufferPointer() -> Bool {
        return true
    }

    func getVideoBuffer(setPointer: UnsafeRawPointer?) -> UnsafeRawPointer {
        self.videoBuffer = setPointer
        return setPointer!
    }
    
    func getAudioFormat() -> AVAudioFormat? {
        return AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 44100.0, channels: 2, interleaved: true)
    }

    // MARK: Emulation lifecycle
    
    func start(url: URL) -> Bool {
        return true
    }
    
    func stop() {}
    
    func play() {}
    
    func pause() {}
    
    func restart() {}
    
    func executeFrame(processVideo: Bool) {
        for i in stride(from: 0, to: audioSampleBuffer.count, by: 2) {
            let value = Int16.random(in: Int16.min...Int16.max)
            audioSampleBuffer[i + 0] = value
            audioSampleBuffer[i + 1] = value
        }
        
        if let ptr = audioSampleBuffer.baseAddress {
            let _ = self.delegate.coreRenderAudio(samples: ptr, byteSize: self.audioSampleBuffer.count * MemoryLayout<Int16>.stride)
        }
        
        guard processVideo else { return }
        
        let count = self.getVideoWidth() * self.getVideoHeight() * self.getVideoPixelFormat().bytesPerPixel
        
        let out = UnsafeMutableRawBufferPointer(start: UnsafeMutableRawPointer(mutating: self.videoBuffer), count: count)
        
        for i in stride(from: 0, to: count, by: 4) {
            let color: UInt8 = Bool.random() ? 255 : 0
            out[i + 0] = color
            out[i + 1] = color
            out[i + 2] = color
        }
    }
    
    // MARK: Save States
    
    func saveState(url: URL) -> Bool {
        return false
    }
    
    func loadState(url: URL) -> Bool {
        return false
    }
    
    // MARK: Controls
    
    func playerConnected() -> Int {
        return 0
    }
    
    func playerDisconnected(player: Int) {}
    
    func playerSetInputs(player: Int, value: UInt32) {}
}
