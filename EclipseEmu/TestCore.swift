import Foundation
import EclipseKit

struct TestCoreSettings: CoreSettings, Codable {
	var hello: Bool = false
	var data: Int = 0
	var bios: CoreSettingsFile?
    
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    
    static let currentVersion: Int16 = 1
    static let descriptor: CoreSettingsDescriptor<Self> = .init(
        sections: [
			.init(
				id: 0,
				title: "General",
				settings: [
					.bool(.init(id: 0, target: \.hello, displayName: "Bool")),
					.radio(.init(id: 1, target: \.data, displayName: "Radio", options: [
						.init(id: 0, displayName: "Foo"),
						.init(id: 1, displayName: "Bar"),
						.init(id: 2, displayName: "Baz"),
						.init(id: 3, displayName: "Biz"),
						.init(id: 4, displayName: "Boz"),
					])),
				]
			),
			.init(id: 1, title: "BIOS", settings: [
				.file(.init(id: 2, target: \.bios, displayName: "File", required: true, type: .binary))
			])
        ]
    )

    static func decode(_ data: Data, version: Int16) throws -> TestCoreSettings {
        guard version == 1 else { return .init() }
        return try Self.decoder.decode(Self.self, from: data)
    }
    
    func encode() throws -> Data {
        try Self.encoder.encode(self)
    }
}

@safe
struct TestCore: CoreProtocol {
    typealias VideoRenderer = CoreFrameBufferVideoRenderer
    typealias Settings = TestCoreSettings

    static let id: String = "testcore"
    static let name: String = "Test Core"
    static let sourceCodeRepository: URL = URL(string: "https://github.com/magnetardev")!
    static let developer: String = "MagnetarDev"
    static let version: String = "0.1.0"
    static let systems: Set<System> = []

    static func features(for system: System) -> CoreFeatures {
        switch system {
        default: []
        }
    }

	static func cheatFormats(for system: EclipseKit.System) -> [EclipseKit.CoreCheatFormat] {
		[]
	}

	var bridge: any CoreBridgeProtocol

    var maxPlayers: UInt8 = 3
	var playerConnectionBehavior: EclipseKit.CorePlayerConnectionBehavior = .linear

	@safe
	var frameBuffer: UnsafeMutableBufferPointer<UInt8>!
    var desiredFrameRate: Double = 60.0

	init(
		system _: System,
		settings _: consuming CoreResolvedSettings<Settings>,
		bridge: any CoreBridgeProtocol
	) throws(any Error) {
		self.bridge = bridge
	}

    func getAudioDescriptor() -> CoreAudioDescriptor {
        .init(sampleRate: 44100, sampleFormat: .int16, channelCount: 2)
    }

    func getVideoDescriptor() -> CoreVideoDescriptor {
        .init(width: 256, height: 256, pixelFormat: .bgra8Unorm, frameBuffer: .assignable)
    }

    mutating func setFrameBuffer(to pointer: UnsafeMutableBufferPointer<UInt8>) {
        self.frameBuffer = unsafe pointer
	}

    func start(romPath _: URL, savePath _: URL) throws(any Error) {}
    func stop() {}

    func play() {}
    func pause() {}

    func reset() {}

    func step(timestamp: CFAbsoluteTime, willRender: Bool) {
        if willRender {
            var i = 0
            while i < self.frameBuffer.count {
                self.frameBuffer[i + 0] = UInt8.random(in: 0...255)
                self.frameBuffer[i + 1] = UInt8.random(in: 0...255)
                self.frameBuffer[i + 2] = UInt8.random(in: 0...255)
                self.frameBuffer[i + 3] = 255
                i += 4
            }
        }
    }
    
    func playerConnected(to port: UInt8) {}

    func playerDisconnected(from port: UInt8) {}

    func writeInput(_ delta: CoreInputDelta, for player: UInt8) {
        print(player, delta)
    }
    
    func setCheat(cheat: CoreCheat, enabled: Bool) {}

    func clearCheats() {}

	func save(to path: URL) async throws(any Error) {}

    func saveState(to path: URL) throws(any Error) {}

    func loadState(from path: URL) throws(any Error) {}
}
