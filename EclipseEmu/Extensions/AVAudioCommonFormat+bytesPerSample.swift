import AVFoundation

extension AVAudioCommonFormat {
    var bytesPerSample: Int {
        switch self {
        case .pcmFormatInt16:
            return MemoryLayout<Int16>.size
        case .pcmFormatInt32:
            return MemoryLayout<Int32>.size
        case .pcmFormatFloat32:
            return MemoryLayout<Float32>.size
        case .pcmFormatFloat64:
            return MemoryLayout<Float64>.size
        default:
            preconditionFailure("unknown byte size for sample format")
        }
    }
}
