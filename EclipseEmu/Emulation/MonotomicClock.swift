import Foundation

// NOTE: 
//  This file is largely based on the Swift standard library for ContinuousClock, as a "polyfill" of sorts for older OS versions.
//  As such, all credit really goes to the Swift people.

@available(iOS, introduced: 15.0, deprecated: 16.0, renamed: "ContinuousClock", message: "This is a general implementation of ContinuousClock for older OSs, use the newer version instead.")
enum MonotomicClock {
    typealias Instant = UInt64
    typealias Duration = UInt64
    
    static let timebase: mach_timebase_info = {
        var timebase = mach_timebase_info()
        mach_timebase_info(&timebase)
        return timebase
    }()
    
    private static let nanosFactor: Double = {
        return (Double(timebase.numer) / Double(timebase.denom))
    }()
    
    private static let secondsFactor: Double = {
        return nanosFactor / 1e9
    }()
    
    @usableFromInline
    static var now: Instant {
        return mach_absolute_time()
    }
    
    @usableFromInline
    static func seconds(_ value: Double) -> MonotomicClock.Instant {
        return UInt64(value / secondsFactor)
    }
    
    @inlinable
    static func sleep(until absolute: MonotomicClock.Instant) async throws {
        let now = MonotomicClock.now
        let duration = UInt64(Double(UInt64(now < absolute) * (absolute &- now)) * Self.nanosFactor)
        try await Task.sleep(nanoseconds: duration)
    }
}
