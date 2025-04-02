import Darwin.C.errno
import EclipseKit
import Foundation

struct CoreCallbacks: ~Copyable {
    private let context: UnsafeMutablePointer<GameCoreCoordinator.CallbackContext>
    let pointer: UnsafeMutablePointer<GameCoreCallbacks>

    init() {
        context = UnsafeMutablePointer<GameCoreCoordinator.CallbackContext>.allocate(capacity: 1)
        context.initialize(to: GameCoreCoordinator.CallbackContext())

        pointer = UnsafeMutablePointer<GameCoreCallbacks>.allocate(capacity: 1)
        pointer.initialize(to: GameCoreCallbacks(
            callbackContext: context,
            didSave: GameCoreCoordinator.didSave,
            writeAudio: GameCoreCoordinator.writeAudio
        ))
    }

    deinit {
        pointer.deallocate()
        context.deallocate()
    }

    @inlinable
    func set(contextParent: GameCoreCoordinator) {
        context.pointee.parent = contextParent
    }
}

struct Core: ~Copyable {
    typealias Context = UnsafeMutableRawPointer?

    private let ctx: Context
    private let callbacks: CoreCallbacks

    private let rawDeallocate: @convention(c) (_ ctx: Context) -> Void

    private let rawGetAudioFormat: @convention(c) (Context) -> GameCoreAudioFormat
    private let rawGetVideoFormat: @convention(c) (Context) -> GameCoreVideoFormat
    private let rawGetDesiredFrameRate: @convention(c) (Context) -> Double
    private let rawCanSetVideoPointer: @convention(c) (Context) -> Bool
    private let rawGetVideoPointer: @convention(c) (
        Context,
        _ preferredPointer: UnsafeMutablePointer<UInt8>?
    ) -> UnsafeMutablePointer<UInt8>?

    private let rawStart: @convention(c) (
        Context,
        _ gamePath: UnsafePointer<CChar>?,
        _ savePath: UnsafePointer<CChar>?
    ) -> Bool
    private let rawStop: @convention(c) (Context) -> Void
    private let rawRestart: @convention(c) (Context) -> Void
    private let rawPlay: @convention(c) (Context) -> Void;
    private let rawPause: @convention(c) (Context) -> Void
    private let rawExecuteFrame: @convention(c) (Context, _ willRender: Bool) -> Void

    private let rawSave: @convention(c) (Context, _ path: UnsafePointer<CChar>?) -> Bool
    private let rawSaveState: @convention(c) (Context, _ path: UnsafePointer<CChar>?) -> Bool
    private let rawLoadState: @convention(c) (Context, _ path: UnsafePointer<CChar>?) -> Bool

    private let rawGetMaxPlayers: @convention(c) (Context) -> UInt8
    private let rawPlayerConnected: @convention(c) (Context, _ player: UInt8) -> Bool
    private let rawPlayerDisconnected: @convention(c) (Context, _ player: UInt8) -> Void
    private let rawPlayerSetInputs: @convention(c) (Context, _ player: UInt8, _ inputs: UInt32) -> Void

    private let rawSetCheat: @convention(c) (
        Context,
        _ format: UnsafePointer<CChar>?,
        _ code: UnsafePointer<CChar>?,
        _ enabled: Bool
    ) -> Bool
    private let rawClearCheats: @convention(c) (Context) -> Void

    init?(from info: CoreInfo, system: GameSystem, callbacks: consuming CoreCallbacks) {
        guard let core = info.setup(system, callbacks.pointer) else { return nil }
        self = .init(raw: core, callbacks: callbacks)
    }

    init(raw: UnsafePointer<GameCore>, callbacks: consuming CoreCallbacks) {
        self.ctx = raw.pointee.data
        self.callbacks = callbacks

        self.rawDeallocate = raw.pointee.deallocate
        self.rawGetAudioFormat = raw.pointee.getAudioFormat
        self.rawGetVideoFormat = raw.pointee.getVideoFormat
        self.rawGetDesiredFrameRate = raw.pointee.getDesiredFrameRate
        self.rawCanSetVideoPointer = raw.pointee.canSetVideoPointer
        self.rawGetVideoPointer = raw.pointee.getVideoPointer
        self.rawStart = raw.pointee.start
        self.rawStop = raw.pointee.stop
        self.rawRestart = raw.pointee.restart
        self.rawPlay = raw.pointee.play
        self.rawPause = raw.pointee.pause
        self.rawExecuteFrame = raw.pointee.executeFrame
        self.rawSave = raw.pointee.save
        self.rawSaveState = raw.pointee.saveState
        self.rawLoadState = raw.pointee.loadState
        self.rawGetMaxPlayers = raw.pointee.getMaxPlayers
        self.rawPlayerConnected = raw.pointee.playerConnected
        self.rawPlayerDisconnected = raw.pointee.playerDisconnected
        self.rawPlayerSetInputs = raw.pointee.playerSetInputs
        self.rawSetCheat = raw.pointee.setCheat
        self.rawClearCheats = raw.pointee.clearCheats
    }

    deinit {
        self.stop()
        self.clearCheats()
        self.rawDeallocate(ctx)
    }

    @inlinable
    func setCallbacksParent(to parent: GameCoreCoordinator) {
        self.callbacks.set(contextParent: parent)
    }
}

extension Core {
    func getDesiredFrameRate() -> Double {
        self.rawGetDesiredFrameRate(ctx)
    }

    @inlinable
    func getAudioFormat() -> GameCoreAudioFormat {
        self.rawGetAudioFormat(ctx)
    }

    @inlinable
    func getVideoFormat() -> GameCoreVideoFormat {
        self.rawGetVideoFormat(ctx)
    }

    @inlinable
    func canSetVideoPointer() -> Bool {
        self.rawCanSetVideoPointer(ctx)
    }

    @inlinable
    func getVideoPointer(setting videoPointer: UnsafeMutablePointer<UInt8>?) -> UnsafeMutablePointer<UInt8>? {
        self.rawGetVideoPointer(ctx, videoPointer)
    }

    @inlinable
    func getMaxPlayers() -> UInt8 {
        self.rawGetMaxPlayers(ctx)
    }
}

extension Core {
    @inlinable
    func start(game gameURL: URL, save saveURL: URL) -> Bool {
        let gamePath = gameURL.path(percentEncoded: false)
        let savePath = saveURL.path(percentEncoded: false)
        return self.rawStart(ctx, gamePath.cString(using: .ascii), savePath.cString(using: .ascii))
    }

    @inlinable
    func stop() -> Void {
        self.rawStop(ctx)
    }

    @inlinable
    func restart() -> Void {
        self.rawRestart(ctx)
    }

    @inlinable
    func play() -> Void {
        self.rawPlay(ctx)
    }

    @inlinable
    func pause() -> Void {
        self.rawPause(ctx)
    }

    @inlinable
    func executeFrame(willRender: Bool) {
        self.rawExecuteFrame(ctx, willRender)
    }
}

extension Core {
    @inlinable
    func save(to url: URL) -> Bool {
        let path = url.path(percentEncoded: false).cString(using: .ascii)
        return self.rawSave(ctx, path)
    }

    @inlinable
    func saveState(to url: URL) -> Bool {
        let path = url.path(percentEncoded: false).cString(using: .ascii)
        return self.rawSaveState(ctx, path)
    }

    @inlinable
    func loadState(from url: URL) -> Bool {
        let path = url.path(percentEncoded: false).cString(using: .ascii)
        return self.rawLoadState(ctx, path)
    }
}

extension Core {
    @inlinable
    func playerConnected(_ player: UInt8) -> Bool {
        self.rawPlayerConnected(ctx, player)
    }

    @inlinable
    func playerDisconnected(_ player: UInt8) -> Void {
        self.rawPlayerDisconnected(ctx, player)
    }

    @inlinable
    func playerSetInputs(_ player: UInt8, _ inputs: UInt32) -> Void {
        self.rawPlayerSetInputs(ctx, player, inputs)
    }
}

extension Core {
    @inlinable
    func setCheat(_ format: String, _ code: String, _ enabled: Bool) -> Bool {
        self.rawSetCheat(ctx, format, code, enabled)
    }

    @inlinable
    func clearCheats() -> Void {
        self.rawClearCheats(ctx)
    }
}
