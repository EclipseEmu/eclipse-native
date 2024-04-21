import Foundation
import AVFoundation
import Metal

@objc(ECGameCoreRenderFormat)
public enum GameCoreRenderFormat: UInt8 {
    case frameBuffer
}

@objc(ECGameSystem)
public enum GameSystem: Int16 {
    case unknown = 0
    case gb = 1
    case gbc = 2
    case gba = 3
    case nes = 4
    case snes = 5
    
    public var string: String {
        return switch self {
        case .unknown:
            "Unknown System"
        case .gb:
            "Game Boy"
        case .gbc:
            "Game Boy Color"
        case .gba:
            "Game Boy Advance"
        case .nes:
            "Nintendo Entertainment System"
        case .snes:
            "Super Nintendo Entertainment System"
        }
    }
}

// FIXME: figure out a way to have associated values to inputs, i.e. for touch: the coordinate. 
//  Since this is a fixed sized list, an array could probably be used (though with an intermediary enum probably).

@objc(ECGameInput)
public enum GameInput: UInt32, RawRepresentable {
    case none                 = 0b00000000_00000000_00000000_00000000
    case faceButtonUp         = 0b00000000_00000000_00000000_00000001
    case faceButtonDown       = 0b00000000_00000000_00000000_00000010
    case faceButtonLeft       = 0b00000000_00000000_00000000_00000100
    case faceButtonRight      = 0b00000000_00000000_00000000_00001000
    case startButton          = 0b00000000_00000000_00000000_00010000
    case selectButton         = 0b00000000_00000000_00000000_00100000
    case shoulderLeft         = 0b00000000_00000000_00000000_01000000
    case shoulderRight        = 0b00000000_00000000_00000000_10000000
    case triggerLeft          = 0b00000000_00000000_00000001_00000000
    case triggerRight         = 0b00000000_00000000_00000010_00000000
    case dpadUp               = 0b00000000_00000000_00000100_00000000
    case dpadDown             = 0b00000000_00000000_00001000_00000000
    case dpadLeft             = 0b00000000_00000000_00010000_00000000
    case dpadRight            = 0b00000000_00000000_00100000_00000000
    case leftJoystickUp       = 0b00000000_00000000_01000000_00000000
    case leftJoystickDown     = 0b00000000_00000000_10000000_00000000
    case leftJoystickLeft     = 0b00000000_00000001_00000000_00000000
    case leftJoystickRight    = 0b00000000_00000010_00000000_00000000
    case rightJoystickUp      = 0b00000000_00000100_00000000_00000000
    case rightJoystickDown    = 0b00000000_00001000_00000000_00000000
    case rightJoystickLeft    = 0b00000000_00010000_00000000_00000000
    case rightJoystickRight   = 0b00000000_00100000_00000000_00000000
    case touchPosX            = 0b00000000_01000000_00000000_00000000
    case touchNegX            = 0b00000000_10000000_00000000_00000000
    case touchPosY            = 0b00000001_00000000_00000000_00000000
    case touchNegY            = 0b00000010_00000000_00000000_00000000
    case lid                  = 0b00000100_00000000_00000000_00000000
    case mic                  = 0b00001000_00000000_00000000_00000000
}

@objc(ECGameCoreDelegate)
public protocol GameCoreDelegate {
    func coreRenderAudio(samples: UnsafeRawPointer, byteSize: UInt64) -> UInt64
    func coreDidSave(at path: URL) -> Void
}

/// You should not do any allocations or setup in the init block. None of the functions will be called until after `setup` is called.
@objc(ECGameCore)
public protocol GameCore {
    var id: String { get }
    var name: String { get }
    
    var delegate: GameCoreDelegate! { get set }
    
    /// Initialize basic info for the system, and perform any known-sized allocations here.
    func setup(system: GameSystem) -> Void
    /// Emulation is about to stop completely, handle any deallocations and other things here.
    func takedown() -> Void
    
    func getMaxPlayers() -> UInt8
    func getDesiredFrameRate() -> Double

    // MARK: Video

    func getVideoPixelFormat() -> MTLPixelFormat
    func getVideoRenderingType() -> GameCoreRenderFormat
    func getVideoWidth() -> Int
    func getVideoHeight() -> Int
    func canSetVideoBufferPointer() -> Bool
    /// Get a pointer to the video buffer. Ideally you'd use the pointer given by `setPointer` as the video buffer. If you cannot, return false in the `canSetVideoBufferPointer` method.
    func getVideoBuffer(setPointer: UnsafeRawPointer?) -> UnsafeRawPointer

    // MARK: Audio

    func getAudioFormat() -> AVAudioFormat?

    // MARK: General lifecycle

    /// Starts the game at the specified path
    func start(url: URL) -> Bool
    
    /// Stops emulation
    func stop() -> Void
    
    /// Resumes playback of the game
    func play() -> Void
    
    /// Pauses playback of the game
    func pause() -> Void
    
    /// Restarts the game
    func restart() -> Void

    /// Emulates a single frame, optionally handling any additional video processing required to render the frame
    func executeFrame(processVideo: Bool) -> Void
    
    // MARK: Save States
    
    func saveState(url: URL) -> Bool
    func loadState(url: URL) -> Bool
    
    // MARK: Controls
    
    /// Notifies that a new player has connected
    func playerConnected(player: UInt8) -> Bool
    /// Notifies that a player has disconnected
    func playerDisconnected(player: UInt8) -> Void
    /// Sets the inputs for a player
    func playerSetInputs(player: UInt8, value: GameInput.RawValue)
}
