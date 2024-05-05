import Foundation
import Atomics

extension UnsafeMutableRawBufferPointer {
    @_noAllocation
    @inlinable
    func copyMemory(offset: Int, from: UnsafeRawPointer, length: Int) {
        guard _fastPath(length > 0) else { return }
        let dst = UnsafeMutableRawBufferPointer(start: self.baseAddress?.advanced(by: offset), count: length)
        let src = UnsafeRawBufferPointer(start: from, count: length)
        dst.copyMemory(from: src)
    }
    
    @_noAllocation
    @inlinable
    func copyMemory(from: UnsafeRawPointer, length: Int) {
        guard _fastPath(length > 0) else { return }
        self.copyMemory(from: UnsafeRawBufferPointer(start: from, count: length))
    }
}

struct RingBuffer: ~Copyable {
    let capacity: Int
    private var head: ManagedAtomic<Int> = .init(0)
    private var tail: ManagedAtomic<Int> = .init(0)
    private var inner: UnsafeMutableRawBufferPointer
    
    init(capacity: Int) {
        self.capacity = capacity
        self.inner = UnsafeMutableRawBufferPointer.allocate(
            byteCount: MemoryLayout<UInt8>.stride * capacity,
            alignment: MemoryLayout<UInt8>.alignment
        )
    }
    
    deinit {
        self.inner.deallocate()
    }
    
    @inlinable
    func availableRead(head: Int, tail: Int) -> Int {
        // NOTE: this is equivalent to `return tail >= head ? tail - head : tail + self.capacity - head;`
        return tail >= head ? tail &- head : tail &+ self.capacity &- head;
    }
    
    @inlinable
    func availableWrite(head: Int, tail: Int) -> Int {
        return tail >= head ? self.capacity &- tail &+ head : head &- tail;
    }
    
    func availableRead() -> Int {
        let head = self.head.load(ordering: .relaxed)
        let tail = self.tail.load(ordering: .relaxed)
        return self.availableRead(head: head, tail: tail)
    }
    
    func availableWrite() -> Int {
        let head = self.head.load(ordering: .relaxed)
        let tail = self.tail.load(ordering: .relaxed)
        return self.availableWrite(head: head, tail: tail)
    }
    
    func read(dst: UnsafeMutableRawPointer, length: Int) -> Int {
        let head = self.head.load(ordering: .acquiring)
        let tail = self.tail.load(ordering: .relaxed)
        
        let available = self.availableRead(head: head, tail: tail)
        guard available >= length, let src = self.inner.baseAddress else { return 0 }
        
        var nextHead = head + length
        let needsWrap = nextHead >= self.capacity
        nextHead -= needsWrap ? self.capacity : 0
        self.head.store(nextHead, ordering: .releasing)

        let len1 = needsWrap ? self.capacity - head : length
        let len2 = needsWrap ? nextHead : 0
        
        let destination = UnsafeMutableRawBufferPointer(start: dst, count: length)
        destination.copyMemory(from: src.advanced(by: head), length: len1)
        destination.copyMemory(offset: head, from: src, length: len2)

        return length
    }
    
    @_transparent
    func write(src: UnsafeRawPointer, length: Int) -> Int {
        let head = self.head.load(ordering: .relaxed)
        let tail = self.tail.load(ordering: .acquiring)
        
        let available = self.availableWrite(head: head, tail: tail)
        guard available >= length else { return 0 }
        
        var nextTail = tail + length
        let needsWrap = nextTail >= self.capacity
        nextTail -= needsWrap ? self.capacity : 0
        self.tail.store(nextTail, ordering: .releasing)

        let len1 = needsWrap ? self.capacity &- tail : length
        let len2 = needsWrap ? nextTail : 0
        
        inner.copyMemory(offset: tail, from: src, length: len1)
        inner.copyMemory(from: UnsafeRawBufferPointer(start: src.advanced(by: len1), count: len2))
        
        return length;
    }
    
    func clear() {
        self.head.store(0, ordering: .relaxed)
        self.tail.store(0, ordering: .relaxed)
    }
}
