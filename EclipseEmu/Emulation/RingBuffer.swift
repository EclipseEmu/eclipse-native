import Foundation
import CoreAudio
import Atomics

// FIXME: figure out proper memory orderings here

final class RingBuffer {
    var buffer: UnsafeMutableRawBufferPointer
    var head: ManagedAtomic<Int> = .init(0)
    var tail: ManagedAtomic<Int> = .init(0)
    let capacity: Int
    let alignment: Int
    
    /// Creates a new Ring Buffer with the given capacity and alignment.
    ///
    /// - Parameters:
    ///   - capacity: The number of bytes used to represent the ring buffer.
    ///   - alignment: The alignment of the buffer, which must be a power of two.
    init(capacity: Int, alignment: Int) {
        self.buffer = .allocate(byteCount: capacity, alignment: alignment)
        self.capacity = capacity
        self.alignment = alignment
    }
    
    deinit {
        self.buffer.deallocate()
    }
    
    @inlinable
    func availableRead(head: Int) -> Int {
        let tail = self.tail.load(ordering: .relaxed)
        return tail >= head
            ? tail - head
            : tail + self.capacity - head;
    }
    
    @inlinable
    func availableRead() -> Int {
        let head = self.head.load(ordering: .relaxed)
        return self.availableRead(head: head)
    }
    
    @inlinable
    func availableWrite(tail: Int) -> Int {
        let head = self.head.load(ordering: .relaxed)
        return tail >= head
            ? self.capacity - tail + head
            : head - tail
    }
    
    @inlinable
    func availableWrite() -> Int {
        let tail = self.tail.load(ordering: .relaxed)
        return self.availableWrite(tail: tail)
    }
    
    /// Reads up to `count` bytes from the ring buffer into the given destination pointer.
    ///
    /// - Parameters:
    ///   - into: the destination for writing bytes into
    ///   - count: the number of bytes to be read
    /// - Returns: The number of bytes read
    func read(into dest: UnsafeMutableRawBufferPointer) -> Bool {
        let head = self.head.load(ordering: .relaxed)
        let available = self.availableRead(head: head)
        guard dest.count != 0 && available >= dest.count else { return false }

        // determine if the read needs to be split
        var nextHead = head + dest.count
        if nextHead > self.capacity {
            nextHead -= self.capacity
            guard let baseAddress = self.buffer.baseAddress else { return false }
            
            let firstCopyLength = self.capacity - head
            
            memcpy(dest.baseAddress, baseAddress.advanced(by: head), firstCopyLength)
            memcpy(dest.baseAddress?.advanced(by: firstCopyLength), baseAddress, nextHead)
        } else {
            memcpy(dest.baseAddress, buffer.baseAddress?.advanced(by: head), nextHead - head)
            nextHead *= Int(nextHead != self.capacity)
        }

        self.head.store(nextHead, ordering: .relaxed);
        return true;
    }
    
    /// Reads up to `count` bytes from the ring buffer into the given destination pointer.
    ///
    /// - Parameters:
    ///   - from: the source to read bytes from
    ///   - count: the number of bytes to be written
    /// - Returns: The number of bytes written
    func write(from source: UnsafeRawBufferPointer) -> Bool {
        // determine if we can write to the buffer
        let tail = self.tail.load(ordering: .relaxed)
        let available = self.availableWrite(tail: tail)
        guard available >= source.count else { return false }

        // determine whether or not we need to split the buffer into two parts
        var nextTail = tail + source.count
        if nextTail >= self.buffer.count {
            nextTail -= self.buffer.count
            guard let baseAddress = self.buffer.baseAddress else { return false }
            
            let firstCopyLength = capacity - tail
            
            memcpy(baseAddress.advanced(by: tail), source.baseAddress, firstCopyLength)
            memcpy(baseAddress, source.baseAddress?.advanced(by: firstCopyLength), nextTail)
        } else {
            guard let destAddress = buffer.baseAddress, let sourceAddress = source.baseAddress else { return false }
            memcpy(destAddress.advanced(by: tail), sourceAddress, source.count)
            nextTail *= Int(nextTail != self.buffer.count)
        }
        
        self.tail.store(nextTail, ordering: .relaxed);
        return true;
    }
    
    func clear() {
        memset(self.buffer.baseAddress, 0, self.buffer.count)
        self.head.store(0, ordering: .relaxed)
        self.tail.store(0, ordering: .relaxed)
    }
}
