import CryptoKit

extension Insecure.SHA1Digest {
    // FIXME: Use base64 for games, switch away from hexString
    consuming func base64() -> String {
        precondition(Self.byteCount == 20)

        return String(unsafeUninitializedCapacity: 27) { ptr in
            self.withUnsafeBytes { bytes in
                (ptr[0], ptr[1], ptr[2], ptr[3]) = b64Triplet(bytes[0], bytes[1], bytes[2])
                (ptr[4], ptr[5], ptr[6], ptr[7]) = b64Triplet(bytes[3], bytes[4], bytes[5])
                (ptr[8], ptr[9], ptr[10], ptr[11]) = b64Triplet(bytes[6], bytes[7], bytes[8])
                (ptr[12], ptr[13], ptr[14], ptr[15]) = b64Triplet(bytes[9], bytes[10], bytes[11])
                (ptr[16], ptr[17], ptr[18], ptr[19]) = b64Triplet(bytes[12], bytes[13], bytes[14])
                (ptr[20], ptr[21], ptr[22], ptr[23]) = b64Triplet(bytes[15], bytes[16], bytes[17])
                (ptr[24], ptr[25], ptr[26], _) = b64Triplet(bytes[18], bytes[19], 0)
            }
            return 27
        }
    }
    
    @inline(__always)
    private func b64Triplet(_ a: UInt8, _ b: UInt8, _ c: UInt8) -> (UInt8, UInt8, UInt8, UInt8) {
        return (
            b64Char(a >> 2),
            b64Char(((a & 0b00000011) << 4) | ((b & 0b11110000) >> 4)),
            b64Char(((b & 0b00001111) << 2) | ((c & 0b11000000) >> 6)),
            b64Char((c & 0b00111111)),
        )
    }

    @inline(__always)
    private func b64Char(_ part: UInt8) -> UInt8 {
        let upperAlpha: UInt8 = part <= 25 ? (part &+ 65) : 0
        let lowerAlpha: UInt8 = part > 25 && part <= 51 ? (part &+ 71) : 0
        let digit: UInt8 = part > 51 && part <= 61 ? (part &- 4) : 0
        let plus: UInt8 = part == 62 ? 43 : 0
        let slash: UInt8 = part == 63 ? 47 : 0
        return upperAlpha &+ lowerAlpha &+ digit &+ plus &+ slash
    }
}

extension Insecure.SHA1Digest {
    func hexString() -> String {
        precondition(Self.byteCount == 20)
        
        return String(unsafeUninitializedCapacity: 40) { ptr in
            self.withUnsafeBytes { bytes in
                var offset: Int = 0
                for i in 0..<20 {
                    let byte = bytes[i]
                    ptr[offset + 0] = hexChar(byte >> 4)
                    ptr[offset + 1] = hexChar(byte & 0b1111)
                    offset += 2
                }
            }
            return 40
        }
    }

    @inline(__always)
    private func hexChar(_ part: UInt8) -> UInt8 {
        return part &+ 48 &+ (part > 0x9 ? 7 : 0)
    }
}


