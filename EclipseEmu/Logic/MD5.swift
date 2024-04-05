import Foundation

fileprivate let BLOCK_SIZE: UInt8 = 64
fileprivate let BLOCK_SIZE_MASK: UInt8 = 0b00111111 // 63, all bits before 64 are on.

fileprivate struct DataByteSequence: AsyncSequence {
    var data: Data
    typealias Element = UInt8

    struct AsyncIterator: AsyncIteratorProtocol {
        var data: Data
        var i = 0
        
        mutating func next() async -> UInt8? {
            defer { i += 1 }
            if i < data.count {
                return data[i]
            } else {
                return nil
            }
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(data: data)
    }
}

struct MD5Hasher: ~Copyable {
    private var input: ContiguousArray<UInt32>
    private var inputBytes: UnsafeMutableBufferPointer<UInt8>
    private var buffer: ContiguousArray<UInt32> = [0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476]
    private var size: UInt64 = 0
    private var offset: UInt8 = 0
    
    init() {
        input = .init(repeating: 0, count: 16)
        // SAFTEY: we want a window of the u32 array, this gives us one. 16 * sizeof(uint32_t) = 64, so our BLOCK_SIZE will ensure no oob accesses.
        inputBytes = input.withUnsafeMutableBytes { ptr in
            return ptr.bindMemory(to: UInt8.self)
        }
    }
    
    /// This function is largely based on the implementation written by Joseph Myers, except with the round functions inlined.
    /// http://www.myersdaily.org/joseph/javascript/md5-text.html
    private mutating func step() {
        var a = buffer[0];
        var b = buffer[1];
        var c = buffer[2];
        var d = buffer[3];
        
        // NOTE: this suffers from CPU pipelining slowdown, but that's kinda inherit to the MD5 algorithm

        // round 1 (f)
        a &+= (((b & c) | (~b & d)) &+ input[0] &- 680876936)
        a = (((a << 7) | (a >> 25)) &+ b)
        d &+= (((a & b) | (~a & c)) &+ input[1] &- 389564586)
        d = (((d << 12) | (d >> 20)) &+ a)
        c &+= (((d & a) | (~d & b)) &+ input[2] &+ 606105819)
        c = (((c << 17) | (c >> 15)) &+ d)
        b &+= (((c & d) | (~c & a)) &+ input[3] &- 1044525330)
        b = (((b << 22) | (b >> 10)) &+ c)
        a &+= (((b & c) | (~b & d)) &+ input[4] &- 176418897)
        a = (((a << 7) | (a >> 25)) &+ b)
        d &+= (((a & b) | (~a & c)) &+ input[5] &+ 1200080426)
        d = (((d << 12) | (d >> 20)) &+ a)
        c &+= (((d & a) | (~d & b)) &+ input[6] &- 1473231341)
        c = (((c << 17) | (c >> 15)) &+ d)
        b &+= (((c & d) | (~c & a)) &+ input[7] &- 45705983)
        b = (((b << 22) | (b >> 10)) &+ c)
        a &+= (((b & c) | (~b & d)) &+ input[8] &+ 1770035416)
        a = (((a << 7) | (a >> 25)) &+ b)
        d &+= (((a & b) | (~a & c)) &+ input[9] &- 1958414417)
        d = (((d << 12) | (d >> 20)) &+ a)
        c &+= (((d & a) | (~d & b)) &+ input[10] &- 42063)
        c = (((c << 17) | (c >> 15)) &+ d)
        b &+= (((c & d) | (~c & a)) &+ input[11] &- 1990404162)
        b = (((b << 22) | (b >> 10)) &+ c)
        a &+= (((b & c) | (~b & d)) &+ input[12] &+ 1804603682)
        a = (((a << 7) | (a >> 25)) &+ b)
        d &+= (((a & b) | (~a & c)) &+ input[13] &- 40341101)
        d = (((d << 12) | (d >> 20)) &+ a)
        c &+= (((d & a) | (~d & b)) &+ input[14] &- 1502002290)
        c = (((c << 17) | (c >> 15)) &+ d)
        b &+= (((c & d) | (~c & a)) &+ input[15] &+ 1236535329)
        b = (((b << 22) | (b >> 10)) &+ c)

        // round 2 (g)
        a &+= (((b & d) | (c & ~d)) &+ input[1] &- 165796510)
        a = (((a << 5) | (a >> 27)) &+ b)
        d &+= (((a & c) | (b & ~c)) &+ input[6] &- 1069501632)
        d = (((d << 9) | (d >> 23)) &+ a)
        c &+= (((d & b) | (a & ~b)) &+ input[11] &+ 643717713)
        c = (((c << 14) | (c >> 18)) &+ d)
        b &+= (((c & a) | (d & ~a)) &+ input[0] &- 373897302)
        b = (((b << 20) | (b >> 12)) &+ c)
        a &+= (((b & d) | (c & ~d)) &+ input[5] &- 701558691)
        a = (((a << 5) | (a >> 27)) &+ b)
        d &+= (((a & c) | (b & ~c)) &+ input[10] &+ 38016083)
        d = (((d << 9) | (d >> 23)) &+ a)
        c &+= (((d & b) | (a & ~b)) &+ input[15] &- 660478335)
        c = (((c << 14) | (c >> 18)) &+ d)
        b &+= (((c & a) | (d & ~a)) &+ input[4] &- 405537848)
        b = (((b << 20) | (b >> 12)) &+ c)
        a &+= (((b & d) | (c & ~d)) &+ input[9] &+ 568446438)
        a = (((a << 5) | (a >> 27)) &+ b)
        d &+= (((a & c) | (b & ~c)) &+ input[14] &- 1019803690)
        d = (((d << 9) | (d >> 23)) &+ a)
        c &+= (((d & b) | (a & ~b)) &+ input[3] &- 187363961)
        c = (((c << 14) | (c >> 18)) &+ d)
        b &+= (((c & a) | (d & ~a)) &+ input[8] &+ 1163531501)
        b = (((b << 20) | (b >> 12)) &+ c)
        a &+= (((b & d) | (c & ~d)) &+ input[13] &- 1444681467)
        a = (((a << 5) | (a >> 27)) &+ b)
        d &+= (((a & c) | (b & ~c)) &+ input[2] &- 51403784)
        d = (((d << 9) | (d >> 23)) &+ a)
        c &+= (((d & b) | (a & ~b)) &+ input[7] &+ 1735328473)
        c = (((c << 14) | (c >> 18)) &+ d)
        b &+= (((c & a) | (d & ~a)) &+ input[12] &- 1926607734)
        b = (((b << 20) | (b >> 12)) &+ c)

        // round 3 (h)
        a &+= ((b ^ c ^ d) &+ input[5] &- 378558)
        a = (((a << 4) | (a >> 28)) &+ b)
        d &+= ((a ^ b ^ c) &+ input[8] &- 2022574463)
        d = (((d << 11) | (d >> 21)) &+ a)
        c &+= ((d ^ a ^ b) &+ input[11] &+ 1839030562)
        c = (((c << 16) | (c >> 16)) &+ d)
        b &+= ((c ^ d ^ a) &+ input[14] &- 35309556)
        b = (((b << 23) | (b >> 9)) &+ c)
        a &+= ((b ^ c ^ d) &+ input[1] &- 1530992060)
        a = (((a << 4) | (a >> 28)) &+ b)
        d &+= ((a ^ b ^ c) &+ input[4] &+ 1272893353)
        d = (((d << 11) | (d >> 21)) &+ a)
        c &+= ((d ^ a ^ b) &+ input[7] &- 155497632)
        c = (((c << 16) | (c >> 16)) &+ d)
        b &+= ((c ^ d ^ a) &+ input[10] &- 1094730640)
        b = (((b << 23) | (b >> 9)) &+ c)
        a &+= ((b ^ c ^ d) &+ input[13] &+ 681279174)
        a = (((a << 4) | (a >> 28)) &+ b)
        d &+= ((a ^ b ^ c) &+ input[0] &- 358537222)
        d = (((d << 11) | (d >> 21)) &+ a)
        c &+= ((d ^ a ^ b) &+ input[3] &- 722521979)
        c = (((c << 16) | (c >> 16)) &+ d)
        b &+= ((c ^ d ^ a) &+ input[6] &+ 76029189)
        b = (((b << 23) | (b >> 9)) &+ c)
        a &+= ((b ^ c ^ d) &+ input[9] &- 640364487)
        a = (((a << 4) | (a >> 28)) &+ b)
        d &+= ((a ^ b ^ c) &+ input[12] &- 421815835)
        d = (((d << 11) | (d >> 21)) &+ a)
        c &+= ((d ^ a ^ b) &+ input[15] &+ 530742520)
        c = (((c << 16) | (c >> 16)) &+ d)
        b &+= ((c ^ d ^ a) &+ input[2] &- 995338651)
        b = (((b << 23) | (b >> 9)) &+ c)

        // round 4 (i)
        a &+= ((c ^ (b | ~d)) &+ input[0] &- 198630844)
        a = (((a << 6) | (a >> 26)) &+ b)
        d &+= ((b ^ (a | ~c)) &+ input[7] &+ 1126891415)
        d = (((d << 10) | (d >> 22)) &+ a)
        c &+= ((a ^ (d | ~b)) &+ input[14] &- 1416354905)
        c = (((c << 15) | (c >> 17)) &+ d)
        b &+= ((d ^ (c | ~a)) &+ input[5] &- 57434055)
        b = (((b << 21) | (b >> 11)) &+ c)
        a &+= ((c ^ (b | ~d)) &+ input[12] &+ 1700485571)
        a = (((a << 6) | (a >> 26)) &+ b)
        d &+= ((b ^ (a | ~c)) &+ input[3] &- 1894986606)
        d = (((d << 10) | (d >> 22)) &+ a)
        c &+= ((a ^ (d | ~b)) &+ input[10] &- 1051523)
        c = (((c << 15) | (c >> 17)) &+ d)
        b &+= ((d ^ (c | ~a)) &+ input[1] &- 2054922799)
        b = (((b << 21) | (b >> 11)) &+ c)
        a &+= ((c ^ (b | ~d)) &+ input[8] &+ 1873313359)
        a = (((a << 6) | (a >> 26)) &+ b)
        d &+= ((b ^ (a | ~c)) &+ input[15] &- 30611744)
        d = (((d << 10) | (d >> 22)) &+ a)
        c &+= ((a ^ (d | ~b)) &+ input[6] &- 1560198380)
        c = (((c << 15) | (c >> 17)) &+ d)
        b &+= ((d ^ (c | ~a)) &+ input[13] &+ 1309151649)
        b = (((b << 21) | (b >> 11)) &+ c)
        a &+= ((c ^ (b | ~d)) &+ input[4] &- 145523070)
        a = (((a << 6) | (a >> 26)) &+ b)
        d &+= ((b ^ (a | ~c)) &+ input[11] &- 1120210379)
        d = (((d << 10) | (d >> 22)) &+ a)
        c &+= ((a ^ (d | ~b)) &+ input[2] &+ 718787259)
        c = (((c << 15) | (c >> 17)) &+ d)
        b &+= ((d ^ (c | ~a)) &+ input[9] &- 343485551)
        b = (((b << 21) | (b >> 11)) &+ c)

        buffer[0] &+= a
        buffer[1] &+= b
        buffer[2] &+= c
        buffer[3] &+= d
    }

    @inline(__always)
    mutating func readByte(byte: UInt8) {
        size += 1
        inputBytes[Int(offset)] = byte
        offset = (offset + 1) & BLOCK_SIZE_MASK
        if offset != 0 {
            return
        }
        step()
    }
    
    consuming func finish() -> ContiguousArray<UInt8> {
        let paddingIters = 56 + (offset >= 56 ? 1 : 0) * BLOCK_SIZE - offset
        var padding: UInt8 = 0x80
        for _ in 0..<paddingIters {
            inputBytes[Int(offset)] = padding
            offset = (offset + 1) & BLOCK_SIZE_MASK
            padding = 0
            if offset != 0 {
                continue
            }
            step()
        }

        let bitSize: UInt64 = size * 8;
        input[14] = UInt32(bitSize & 0xffffffff) // not sure if a UInt32 cast will trunc on its own
        input[15] = UInt32(bitSize >> 32)
        step();

        var digest = ContiguousArray<UInt8>(repeating: 0, count: 16);
        for i in 0..<4 {
            let byte = buffer[i];
            let digestStart = i << 2;
            digest[digestStart] = UInt8(byte & 0x000000ff)
            digest[digestStart + 1] = UInt8((byte & 0x0000ff00) >> 8)
            digest[digestStart + 2] = UInt8((byte & 0x00ff0000) >> 16)
            digest[digestStart + 3] = UInt8((byte & 0xff000000) >> 24)
        }
        return digest
    }
    
    consuming func hash<T: AsyncSequence>(seq: T) async throws -> ContiguousArray<UInt8> where T.Element == UInt8 {
        for try await byte in seq {
            readByte(byte: byte)
        }
        return finish()
    }

    consuming func hash(data: Data) async throws -> ContiguousArray<UInt8> {
        for byte in data {
            readByte(byte: byte)
        }
        return finish()
    }
    
    static func stringFromDigest(digest: ContiguousArray<UInt8>) -> String {
        var string = ""
        for byte in digest {
            let str = String(byte, radix: 16)
            string += String(repeating: "0", count: 2 - str.count) + str
        }
        return string
    }
}
