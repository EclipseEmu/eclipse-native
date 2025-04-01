enum ControlsInputSourceKind: Int16, RawRepresentable {
    case unknown = 0
    case touch = 1
    case keyboard = 2
    case controller = 3
}

enum ControlsInputError: Error {
    case unsupportedVersion
}
