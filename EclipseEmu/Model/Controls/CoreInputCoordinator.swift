import GameController
import AtomicCompat
import EclipseKit
import Foundation

@safe
final actor CoreInputCoordinator {
	/// Called whenever a connection changes.
    ///
    /// - Parameter context: The context for this reorder request
    /// - Parameter player: The player that triggered the reordering to occur.
    typealias ReorderHandler = @MainActor (()) async -> Void

    private let executor: DispatchQueueSerialExecutor
    nonisolated let unownedExecutor: UnownedSerialExecutor

    let bindings: ControlBindingsManager

    private let listening: Atomic<Bool> = .init(false)
    private let maxPlayers: UInt8
    private var players: [GCController?]
	private var keyboardState: InputSourceState
	private var controllerState: [InputSourceState]
    nonisolated let states: CoreInputDeque

    private let reorderHandler: ReorderHandler
    private var connectionListener: Task<Void, Never>?

    init(
		maxPlayers: UInt8,
		bindings: ControlBindingsManager,
		reorder reorderHandler: @escaping ReorderHandler
	) {
        let queue = DispatchQueue(label: "dev.magnetar.eclipseemu.queue.coreinputcoordinator")
		self.executor = .init(queue: queue)
        unsafe self.unownedExecutor = executor.asUnownedSerialExecutor()

        self.maxPlayers = maxPlayers
		let intMaxPlayers = Int(maxPlayers)
		self.players = .init(repeating: nil, count: intMaxPlayers)
		self.keyboardState = .init()
		self.controllerState = .init(repeating: .init(), count: intMaxPlayers)
        self.states = .init(maxPlayers: maxPlayers)
        self.bindings = bindings
        self.reorderHandler = reorderHandler
    }

	nonisolated func runIsolated<T>(_ operation: @escaping @Sendable (isolated CoreInputCoordinator) -> T) -> T {
		typealias YesActor = (isolated CoreInputCoordinator) -> T
		typealias NoActor = (CoreInputCoordinator) -> T

		dispatchPrecondition(condition: .onQueue(self.executor.queue))

		return withoutActuallyEscaping(operation) { (_ fn: @escaping YesActor) -> T in
			let rawFn = unsafe unsafeBitCast(fn, to: NoActor.self)
			return rawFn(self)
		}
	}

    private nonisolated func playerIndex(for controller: GCController) -> UInt8? {
        let controller = unsafe UnsafeSend(controller)
		
		return runIsolated { this in
            unsafe this.players.firstIndex(of: controller.inner).map(UInt8.init)
        }
    }

    @inlinable
    nonisolated func read<Core: CoreProtocol & ~Copyable>(into core: inout Core) {
        states.dequeue(into: &core)
    }

    func start() async {
        let controllers = GCController.controllers()
        for controller in controllers {
            await attachController(controller: controller)
        }

        if let keyboard = GCKeyboard.coalesced {
            await attachKeyboard(keyboard: keyboard)
        }

        self.connectionListener?.cancel()
        self.connectionListener = Task {
            let nc = NotificationCenter.default
            async let keyboardConnections: () = listenForKeyboardConnections(nc)
            async let keyboardDisconnections: () = listenForKeyboardDisconnections(nc)
            async let controllerConnections: () = listenForControllerConnections(nc)
            async let controllerDisconnections: () = listenForControllerDisconnections(nc)

            _ = await (keyboardConnections, keyboardDisconnections, controllerConnections, controllerDisconnections)
        }
        self.resume()
    }

    func stop() {
        self.pause()
        let controllers = GCController.controllers()
        for controller in controllers {
            detachController(controller: controller)
        }

        if let keyboard = GCKeyboard.coalesced {
            detachKeyboard(keyboard: keyboard)
        }

        self.connectionListener?.cancel()
        self.connectionListener = nil
    }

    @inlinable
    nonisolated func pause() -> Void {
        listening.store(false, ordering: .relaxed)
    }

    @inlinable
    nonisolated func resume() -> Void {
        listening.store(true, ordering: .relaxed)
    }

	func reorder(controller: GCController, isConnected: Bool) async {
        pause()

		// reset input states
		for i in 0..<players.count {
			guard i == 0 || players[i] != nil else { continue }
			states.enqueue(.init(input: .allOn, value: .zero, timestamp: CACurrentMediaTime()), for: UInt8(i))
		}

		// FIXME: actually do reordering

        resume()
    }
}

// MARK: Keyboards

extension CoreInputCoordinator {
    private func listenForKeyboardConnections(_ center: NotificationCenter) async {
        let iter = unsafe center
            .notifications(named: .GCKeyboardDidConnect)
            .compactMap { unsafe ($0.object as? GCKeyboard).map(UnsafeCopyableSend.init) }

        for await unsafe source in unsafe iter {
            unsafe await attachKeyboard(keyboard: source.inner)
        }
    }

    private func listenForKeyboardDisconnections(_ center: NotificationCenter) async {
        let iter = unsafe center
            .notifications(named: .GCKeyboardDidDisconnect)
            .compactMap { unsafe ($0.object as? GCKeyboard).map(UnsafeCopyableSend.init) }

        for await unsafe source in unsafe iter {
            unsafe detachKeyboard(keyboard: source.inner)
        }
    }

    private func attachKeyboard(keyboard: GCKeyboard) async {
        guard let input = keyboard.keyboardInput else { return }
		keyboard.handlerQueue = self.executor.queue

		let mappings = await bindings.load(for: InputSourceKeyboardDescriptor())

		var controls: [ControlState] = []
		var id = 0
		for (key, binding) in mappings {
            input.button(forKeyCode: key)?.pressedChangedHandler = { [weak self, id, binding] _, _, pressed in
				self?.keyboardButtonValueHandler(id: id, binding: binding, isPressed: pressed)
            }
			controls.append(.init(input: binding.input))
			id += 1
        }
		keyboardState.controls = controls
    }

    private func detachKeyboard(keyboard: GCKeyboard) {
        keyboard.handlerQueue = DispatchQueue.main
    }

	private nonisolated func keyboardButtonValueHandler(id: Int, binding: KeyboardMapping, isPressed: Bool) {
        guard listening.load(ordering: .relaxed) else { return }
		let (x, y) = binding.direction.intoValues(isPressed: isPressed)
		runIsolated { this in
			this.keyboardState.enqueue(binding.input, value: .init(x, y), control: id, player: 0, deque: this.states)
		}
    }
}

// MARK: Gamepads

extension CoreInputCoordinator {
    private func listenForControllerConnections(_ center: NotificationCenter) async {
        let iter = unsafe center
            .notifications(named: .GCControllerDidConnect)
            .compactMap { unsafe ($0.object as? GCController).map(UnsafeCopyableSend.init) }

        for await unsafe source in unsafe iter {
			let controller = source.inner
			await attachController(controller: controller)
			await reorder(controller: controller, isConnected: true)
        }
    }

    private func listenForControllerDisconnections(_ center: NotificationCenter) async {
        let iter = unsafe center
            .notifications(named: .GCControllerDidDisconnect)
            .compactMap { unsafe ($0.object as? GCController).map(UnsafeCopyableSend.init) }
        for await unsafe source in unsafe iter {
			let controller = source.inner
            detachController(controller: controller)
            await reorder(controller: controller, isConnected: false)
        }
    }

    private func attachController(controller: GCController) async {
		controller.handlerQueue = self.executor.queue

		let mappings = await bindings.load(for: controller.inputSourceDescriptor)

		var player = -1
		for i in 0..<Int(self.maxPlayers) {
			if self.players[i] == nil {
				self.players[i] = controller
				player = i
			}
		}

        let gamepad = controller.physicalInputProfile
		var id = 0

		var controls: [ControlState] = []
        for (key, binding) in mappings.bindings {
            switch binding {
            case .button(let i):
                let binding = mappings.buttons[i]
                guard let input = gamepad.buttons[key] else { continue }
                input.valueChangedHandler = { [weak self, binding, weak controller, id] _, value, pressed in
                    self?.controllerButtonValueHandler(
						id: id,
						binding: binding,
						controller: controller,
						value: value,
						isPressed: pressed
					)
                }
				controls.append(.init(input: binding.hard.union(binding.soft)))
				id += 1
            case .directional(let i):
                guard let input = gamepad.dpads[key] else { continue }
                let binding = mappings.directionals[i]
                input.valueChangedHandler = { [weak self, binding, weak controller, id] _, x, y in
					self?.controllerDirectionalValueHandler(
						id: id,
						binding: binding,
						controller: controller,
						x: x,
						y: y
					)
                }
				controls.append(.init(input: binding.input))
				id += 1
            }
        }

		if player != -1 {
			controllerState[player].controls = controls
		}
    }

    private func detachController(controller: GCController) {
        controller.handlerQueue = DispatchQueue.main
        if let i = players.firstIndex(of: controller) {
			self.players[i] = nil
        }
    }

    private nonisolated func controllerButtonValueHandler(
		id: Int,
        binding: GamepadMappings.ButtonBinding,
        controller: GCController?,
        value: Float,
        isPressed: Bool
    ) {
		guard
            listening.load(ordering: .relaxed),
            let controller,
            let player = playerIndex(for: controller)
        else { return }

		let input = value > 0.5 ? binding.hard : binding.soft
		let value = SIMD2<Float32>(
			isPressed ? 1 : 0,
			isPressed ? value : 0
		)

		runIsolated { this in
			this.controllerState[Int(player)]
				.enqueue(input, value: value, control: id, player: player, deque: this.states)
		}
    }

    private nonisolated func controllerDirectionalValueHandler(
		id: Int,
		binding: GamepadMappings.DirectionalBinding,
        controller: GCController?,
        x: Float,
        y: Float
    ) {
        guard
            listening.load(ordering: .relaxed),
            let controller,
            let player = playerIndex(for: controller)
        else { return }

        let posDeadZone = binding.deadzone
        let negDeadZone = -posDeadZone
        let x = x > posDeadZone || x < negDeadZone ? x : 0.0
        let y = y > posDeadZone || y < negDeadZone ? y : 0.0
		
		runIsolated { this in
			this.controllerState[Int(player)]
				.enqueue(binding.input, value: .init(x, y), control: id, player: player, deque: this.states)
		}
    }
}
