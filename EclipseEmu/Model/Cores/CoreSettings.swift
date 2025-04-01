import EclipseKit

// MARK: Definition

struct CoreSettingDefinitionFile {
    /// The expected MD5 checksum of the file.
    let sha1: String
    /// The user-shown name of the file.
    let displayName: String

    init?(raw: UnsafePointer<GameCoreSettingFile>?) {
        guard let raw else { return nil }
        // FIXME: this should be SHA-1 on the core side of things
        self.sha1 = String(cString: raw.pointee.md5)
        self.displayName = String(cString: raw.pointee.displayName)
    }
}

struct CoreSettingDefinitionBool {
    /// The default value of this setting
    let defaultValue: Bool

    init?(raw: UnsafePointer<GameCoreSettingBoolean>?) {
        guard let raw else { return nil }
        self.defaultValue = raw.pointee.defaultValue
    }
}

enum CoreSettingDefinitionKind {
    case unknown
    case file(CoreSettingDefinitionFile)
    case bool(CoreSettingDefinitionBool)
}

struct GameCoreSettingDefinition: Identifiable {
    /// The core-unique identifier for this setting.
    let id: String
    /// The system this applies to, use ``EKGameSystemUnknown`` if it applies to
    /// any system.
    let system: GameSystem
    /// The user-shown name of this setting.
    let displayName: String
    /// Whether or not this setting is required for the core to run.
    let required: Bool
    /// What type of setting this will be.
    let kind: CoreSettingDefinitionKind

    init(raw: GameCoreSetting) {
        self.id = String(cString: raw.id)
        self.system = raw.system
        self.displayName = String(cString: raw.displayName)
        self.required = raw.required
        self.kind = switch raw.kind {
        case .boolean:
            if let definition = CoreSettingDefinitionBool(raw: raw.boolean) {
                .bool(definition)
            } else {
                .unknown
            }
        case .file:
            if let definition = CoreSettingDefinitionFile(raw: raw.file) {
                .file(definition)
            } else {
                .unknown
            }
        @unknown default:
            .unknown
        }
    }
}

struct CoreSettingsDefinition {
    /// The version of these settings.
    let version: UInt16
    /// The list of settings.
    let items: [GameCoreSettingDefinition]

    init(raw: GameCoreSettings) {
        self.version = raw.version
        self.items = UnsafeBufferPointer(start: raw.items, count: raw.itemsCount).map(GameCoreSettingDefinition.init)
    }
}

// MARK: Values

// FIXME: create structs and such
