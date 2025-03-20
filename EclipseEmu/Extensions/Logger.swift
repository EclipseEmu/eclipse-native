import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!

    static let coredata = Logger(subsystem: subsystem, category: "coredata")
    static let fs = Logger(subsystem: subsystem, category: "filesystem")
    static let emulation = Logger(subsystem: subsystem, category: "emulation")
}
