import Foundation
import SwiftUI
import Metal
import EclipseKit

final class DummyCore: GameCore {
    static var id: String = "dev.magnetar.dummycore"
    static var name: String = "Dummy Core"
    
    var videoBuffer: UnsafeRawPointer!
    
    func setup() {}
    
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
        true
    }

    func getVideoBuffer(setPointer: UnsafeRawPointer?) -> UnsafeRawPointer {
        self.videoBuffer = setPointer
        return setPointer!
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
        guard processVideo else { return }
        
        var i = 0
        let count = self.getVideoWidth() * self.getVideoHeight() * self.getVideoPixelFormat().bytesPerPixel
        
        let out = UnsafeMutableRawBufferPointer(start: UnsafeMutableRawPointer(mutating: self.videoBuffer), count: count)
        
        while i < count {
            let color: UInt8 = Bool.random() ? 255 : 0
            out[i + 0] = color
            out[i + 1] = color
            out[i + 2] = color
            
            i += 4
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
