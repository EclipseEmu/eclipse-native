import QuartzCore
import EclipseKit
import OSLog

enum CoreCoordinatorError: Error {
	case invalidAudioFormat
}

private struct CoreInstantiation<Core: CoreProtocol>: ~Copyable {
	let bridge: CoreCoordinator<Core>.Bridge
	let core: Core
}

extension NSNotification.Name {
    static let EKGameCoreDidSave = NSNotification.Name("EKGameCoreDidSaveNotification")
}

enum CoreCoordinatorState: UInt8, RawRepresentable {
    case stopped = 0
    case running = 1
    case backgrounded = 2
    case pendingUserInput = 3
    case paused = 4
}

enum EmulationSpeed: Float, CaseIterable, Equatable, Hashable {
	case x0_50 = 0.5
	case x0_75 = 0.75
	case x1_00 = 1
	case x1_25 = 1.25
	case x1_50 = 1.5
	case x1_75 = 1.75
	case x2_00 = 2
}

@safe
final actor CoreCoordinator<Core: CoreProtocol>: CAMetalDisplayLinkDelegate {
	private let executor: SingleThreadedExecutor
	let unownedExecutor: UnownedSerialExecutor

	public nonisolated let system: System
	public let coreID: Eclipse.Core
	private var core: Core
	let inputs: CoreInputCoordinator
	let video: CoreVideoRendererProtocol
	let audio: CoreAudioRenderer

	private var frameInterval: Double = 1.0
	private var lastTimestamp: Double = .infinity
	private(set) var state: CoreCoordinatorState = .stopped
	private var initialTime: TimeInterval = 0
	private var time: TimeInterval = 0
	// 1000 (for ms) / 60 (for fps) / 1000 (convert to seconds)
	private var coreFrameDuration: TimeInterval = 0.0

	nonisolated let screen: CGSize
	nonisolated(unsafe) private let pixelFormat: CoreVideoDescriptor.PixelFormat

	private var displayLink: MetalDisplayLink?
	let sharedRenderingContext: CoreSharedRenderingContext

	final class Bridge: CoreBridgeProtocol {
		weak var instance: CoreCoordinator<Core>?

		func writeAudioSamples(samples: UnsafeRawBufferPointer) -> Int {
			guard let instance, let baseAddress = samples.baseAddress else { return 0 }
			_onFastPath()
			return unsafe instance.audio.write(samples: baseAddress, count: samples.count)
		}

		func didSave() {
            Task { @MainActor in
                NotificationCenter.default.post(name: .EKGameCoreDidSave, object: nil)
            }
		}
	}

	init(
		coreID: Eclipse.Core,
		system: System,
		settings: Core.Settings,
		bindings: consuming ControlBindingsManager,
		reorder: @escaping CoreInputCoordinator.ReorderHandler
	) async throws {
		self.coreID = coreID
		executor = await .init(name: "test-single-threaded", qos: .userInitiated)
		unsafe unownedExecutor = executor.asUnownedSerialExecutor()
		sharedRenderingContext = try await CoreSharedRenderingContext()
		self.system = system


		// Make sure the core is initialized on the thread.
		let instantiation: CoreInstantiation<Core> = try unsafe await executor.run {
			let bridge = Bridge()
			let core = try Core(system: system, settings: .init(settings: settings, resolvedFiles: [:]), bridge: bridge)
			return UnsafeSend(CoreInstantiation(bridge: bridge, core: core))
		}.inner

		let bridge = instantiation.bridge
		var coreInstance = instantiation.core

		// setup audio
		let audioDescriptor = coreInstance.getAudioDescriptor()
		guard let audioFormat = audioDescriptor.getAudioFormat() else {
			throw CoreCoordinatorError.invalidAudioFormat
		}
		audio = CoreAudioRenderer(format: audioFormat)

		// setup video
		let videoDescriptor = coreInstance.getVideoDescriptor()
		screen = .init(width: CGFloat(videoDescriptor.width), height: CGFloat(videoDescriptor.height))
		pixelFormat = videoDescriptor.pixelFormat
		video = try await Core.VideoRenderer(
			core: &coreInstance,
			for: videoDescriptor,
			with: sharedRenderingContext,
			isolation: #isolation // using self here makes the compiler worry that things haven't been fully initalized
		)

		inputs = .init(maxPlayers: coreInstance.maxPlayers, bindings: bindings, reorder: reorder)
		core = coreInstance
		bridge.instance = self
	}

	@inlinable
	nonisolated func runIsolated(_ operation: @escaping @Sendable (isolated CoreCoordinator<Core>) -> Void) -> Void {
		typealias YesActor = (isolated CoreCoordinator<Core>) -> Void
		typealias NoActor = (CoreCoordinator<Core>) -> Void

		if self.executor.isIsolated {
			_onFastPath()
			return withoutActuallyEscaping(operation) { (_ fn: @escaping YesActor) -> Void in
				let rawFn = unsafe unsafeBitCast(fn, to: NoActor.self)
				return rawFn(self)
			}
		} else {
			Logger.emulation.warning("running outside of isolation – switching back \(Thread.current)")
			Task(priority: .high) {
				await operation(self)
			}
		}
	}

	func start(romPath: URL, savePath: URL) async throws {
		try core.start(romPath: romPath, savePath: savePath)
		initialTime = CACurrentMediaTime()
		time = 0
		frameInterval = 1000 / core.desiredFrameRate / 1000
		coreFrameDuration = frameInterval
		await inputs.start()
		await audio.start()
		await self.play(reason: .stopped)
	}

	func stop() async {
		self.displayLink?.displayLink.isPaused = true
		await inputs.stop()
		await audio.stop()
		core.stop()
	}

	func reset() async {
		if state == .running {
			await audio.pause()
			initialTime = CACurrentMediaTime()
			time = 0
			self.displayLink?.displayLink.isPaused = true
		}
		await audio.clear()
		core.reset()
		await audio.resume()
        self.displayLink?.displayLink.isPaused = false
		state = .running
	}

	func play(reason: CoreCoordinatorState) async {
		guard state.rawValue <= reason.rawValue else { return }
		state = .running
		core.play()
		inputs.resume()
		await audio.resume()
		initialTime = CACurrentMediaTime()
		time = 0
		self.displayLink?.displayLink.isPaused = false
	}

	func pause(reason: CoreCoordinatorState) async {
		guard state.rawValue < reason.rawValue || reason == .stopped else { return }
		state = reason

		self.displayLink?.displayLink.isPaused = true
		await audio.pause()
		core.pause()
		inputs.pause()
	}

	func frameStep(targetTimestamp: CFTimeInterval, drawable: any CAMetalDrawable) {
		let start = CACurrentMediaTime()
		let expectedTime = start - initialTime

		let maxCatchupRate: TimeInterval = 5 * coreFrameDuration
		time = max(time, expectedTime - maxCatchupRate)

		var doRender = false
		while time <= expectedTime {
			time += coreFrameDuration
			doRender = time >= expectedTime

			inputs.read(into: &core)
			core.step(timestamp: lastTimestamp, willRender: doRender)
		}

		if doRender {
			video.render(targetTime: targetTimestamp, drawable: drawable, outputTexture: drawable.texture)
		}
	}

	func setFastForward(to rate: EmulationSpeed) async {
		self.coreFrameDuration = self.frameInterval / Double(rate.rawValue)
        await self.audio.setRate(rate: rate.rawValue)
	}

	// MARK: Display Link Handling

	@objc
	@available(macOS, deprecated: 14.0, renamed: "metalDisplayLink", message: "Use the display link intended for metal instances.")
	@available(iOS, deprecated: 17.0, renamed: "metalDisplayLink", message: "Use the display link intended for metal instances.")
	nonisolated func standardDisplayLink(displaylink: CADisplayLink) {
		let targetTimestamp = displaylink.targetTimestamp
		runIsolated { this in
			guard let drawable = this.displayLink?.layer.nextDrawable() else { return }
			_onFastPath()
			this.frameStep(targetTimestamp: targetTimestamp, drawable: drawable)
		}
	}

	@objc
	@available(iOS 17.0, macOS 14.0, *)
	nonisolated func metalDisplayLink(_ link: CAMetalDisplayLink, needsUpdate update: CAMetalDisplayLink.Update) {
		let drawable = unsafe UnsafeSend(update.drawable)
		let targetTimestamp = update.targetTimestamp
		runIsolated { this in
			unsafe this.frameStep(targetTimestamp: targetTimestamp, drawable: drawable.inner)
		}
	}

	@MainActor
	func attach(to surface: some MetalRenderingSurface) async {
		guard let layer = surface.getLayer() else { return }

		layer.device = self.sharedRenderingContext.device
		layer.drawableSize = self.screen
		layer.pixelFormat = pixelFormat.metalFormat
		layer.framebufferOnly = true
		layer.isOpaque = true
		layer.magnificationFilter = .nearest

		if #available(iOS 17.0, *) {
			unsafe await createMetalDisplayLink(for: .init(layer))
		} else if let displayLink = surface.makeStandardDisplayLink(target: self, selector: #selector(standardDisplayLink)) {
			unsafe await createStandardDisplayLink(for: .init(displayLink), with: .init(layer))
		}
	}

	private func createStandardDisplayLink(
		for displayLink: consuming UnsafeSend<CADisplayLink>,
		with layer: consuming UnsafeSend<CAMetalLayer>
	) async {
		let layer = unsafe layer.inner
		if let existingDisplayLink = self.displayLink.take() {
			_ = consume existingDisplayLink
		}
		self.displayLink = unsafe .init(layer: layer, displayLink: displayLink.inner)
		unsafe self.executor.addTimer(displayLink.inner, forMode: .default)
	}

	@available(iOS 17.0, *)
	private func createMetalDisplayLink(for layer: consuming UnsafeSend<CAMetalLayer>) async {
		let layer = unsafe layer.inner
		let displayLink = CAMetalDisplayLink(metalLayer: layer)
		self.displayLink = .init(layer: layer, displayLink: displayLink)
		displayLink.isPaused = false
		displayLink.delegate = self
		self.executor.addTimer(displayLink, forMode: .default)
	}
}

extension CoreCoordinator {
//	@inlinable
//	func save(to url: URL) async throws(Core.Failure) {
//		try await core.save(to: url)
//    }

	@inlinable
	func saveState(to path: URL) throws(Core.Failure) {
		try core.saveState(to: path)
	}

	@inlinable
	func loadState(from url: URL) throws(Core.Failure) {
		try core.loadState(from: url)
	}

	func screenshot() -> CoreSharedRenderingContext.Image? {
		let colorspace = self.displayLink?.layer.colorspace ?? CGColorSpaceCreateDeviceRGB()
		return video.screenshot(colorspace: colorspace)
	}
}

extension CoreCoordinator {
	func setCheats(cheats: [(cheat: CoreCheat, isEnabled: Bool)]) {
		core.clearCheats()
		for cheat in cheats {
			core.setCheat(cheat: cheat.cheat, enabled: cheat.isEnabled)
		}
	}
}
