import UniformTypeIdentifiers

// MARK: ROMs

extension UTType {
    static let romGB = UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gb")
    static let romGBC = UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gbc")
    static let romGBA = UTType(exportedAs: "dev.magnetar.eclipseemu.rom.gba")
    static let romNES = UTType(exportedAs: "dev.magnetar.eclipseemu.rom.nes")
    static let romSNES = UTType(exportedAs: "dev.magnetar.eclipseemu.rom.snes")

    static let allRomFileTypes: [UTType] = [.romGB, .romGBC, .romGBA, .romNES, .romSNES]
}

// MARK: Misc.

extension UTType {
    static let save = UTType(exportedAs: "dev.magnetar.eclipseemu.save")
    static let saveState = UTType(exportedAs: "dev.magnetar.eclipseemu.saveState")
}
