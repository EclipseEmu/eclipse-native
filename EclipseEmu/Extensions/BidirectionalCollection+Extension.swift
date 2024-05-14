import Foundation

extension BidirectionalCollection where Element == UInt8 {
    func hexString() -> String {
        var string = ""
        for byte in self {
            string += String(byte, radix: 16).leftPad(count: 2, with: "0")
        }
        return string
    }
}
