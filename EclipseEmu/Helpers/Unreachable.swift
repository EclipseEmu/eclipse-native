/// Marks a branch as unreachable, meaning it can be omitted.
/// Using just fatalError will add logs to the call site which, when this is used properly, is bloat.
@inlinable
func unreachable(
    _ message: @autoclosure () -> String = "unreachable",
    file: StaticString = #file,
    line: UInt = #line
) -> Never {
#if DEBUG
    fatalError(message(), file: file, line: line)
#else
    unsafeBitCast((), to: Never.self)
#endif
}
