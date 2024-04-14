import Foundation
import AVFoundation
import EclipseKit

class GameAudio {
    let audio = AVAudioEngine()
    let core: GameCore
    
    var volume: Double {
        didSet {
            print("set volume to", volume)
        }
    }
    
    public init(core: GameCore) {
        self.core = core
        self.volume = 1.0
    }
}
