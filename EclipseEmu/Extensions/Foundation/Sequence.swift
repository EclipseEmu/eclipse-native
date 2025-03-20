import Foundation

extension Sequence where Element == UInt8 {
    func hexString() -> String {
        var string = ""
        for byte in self {
            string += (byte > 15 ? "" : "0") + String(byte, radix: 16).uppercased()
        }
        return string
    }
}
