import EclipseKit
import QuartzCore

struct ControlState {
	var input: CoreInput
	var value: SIMD2<Float> = .init(0, 0)

	@inlinable
	var isActive: Bool {
		(value.x != 0 && value.x.isFinite) || (value.y != 0 && value.y.isFinite)
	}
}

struct InputSourceState {
	/// A list of the active controls.
	var controls: [ControlState] = []
	/// The number of inputs that are on, the index being the input's bit offset (trailing).
	private var inputCounts: [Int8] = .init(repeating: 0, count: CoreInput.allCases.count)

	/// Checks if it is safe to release a input, i.e. if two controls activate the input, releasing one should not release both.
	mutating func enqueue(_ input: CoreInput, value: SIMD2<Float>, control: Int, player: UInt8, deque: borrowing CoreInputDeque) {
		let newState = ControlState(input: input, value: value)
		let isActive = newState.isActive
		// NOTE: Potential panic here, we assume that control will always be 0..<self.activeControls.count by this point.
		let hasChange = self.controls[control].isActive != isActive
		self.controls[control] = newState

		let bumpValue: Int8 = hasChange ? (isActive ? 1 : -1) : 0
		let rawInput = input.rawValue
		var rawOffInputs: UInt32 = 0

		let isInactive = !isActive
		var tmp = rawInput
		while tmp != 0 {
			let i = tmp.trailingZeroBitCount
			let component: UInt32 = (1 << i)
			tmp &= ~component
			let newState = max(0, inputCounts[i] &+ bumpValue) // if you have >127 buttons... sorry?
			inputCounts[i] = newState
			rawOffInputs |= (UInt32(isInactive && newState == 0) * component)
		}

		let hasNoRemovals = rawOffInputs == 0
		guard hasNoRemovals && isInactive else {
			let input = !hasNoRemovals && rawInput != rawOffInputs ? CoreInput(rawValue: rawOffInputs) : input
			deque.enqueue(.init(input: input, value: value, timestamp: CACurrentMediaTime()), for: player)
			return
		}

		// we need to poll to make sure we're not conflicting with any other controls.
		for control in controls {
			guard (control.input.rawValue & input.rawValue) != 0, control.isActive else { continue }
			deque.enqueue(.init(input: control.input, value: control.value, timestamp: CACurrentMediaTime()), for: player)
		}
	}
}
