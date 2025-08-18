#if canImport(UIKit)
import SwiftUI
import EclipseKit

struct TouchControlsView: UIViewControllerRepresentable {
    let mappings: TouchMappings
	let coordinator: CoreInputCoordinator
	let namingConvention: ControlNamingConvention
	let screenOffsetChanged: (TouchMappings.ScreenOffset) -> Void
    let menuButtonPlacementChanged: (CGRect) -> Void

    func makeUIViewController(context: Context) -> TouchControlsViewController {
        return TouchControlsViewController(
			mappings: mappings,
			coordinator: coordinator,
			namingConvention: namingConvention,
            menuButtonPlacementChanged: menuButtonPlacementChanged,
			screenOffsetChanged: screenOffsetChanged,
		)
    }
    
    func updateUIViewController(_ vc: TouchControlsViewController, context: Context) {}
}

protocol TouchControlsDirectionalViewProtocol: UIView {
    var directional: TouchMappings.Directional { get }
	var parent: TouchControlsViewController! { get set }
}

final class TouchControlsViewController: UIViewController {
	private var variantIndex: Int = -1
	private var mappings: TouchMappings
	private let directionalPads: [any TouchControlsDirectionalViewProtocol]
	private let buttons: [TouchControlsButtonView]
	private let haptics: UIImpactFeedbackGenerator
	private let touchControlsSubview: UIView
	private let coordinator: CoreInputCoordinator
    private let menuButtonPlacementChanged: (CGRect) -> Void
	private let screenOffsetChanged: (TouchMappings.ScreenOffset) -> Void
	var state: InputSourceState

	init(
		mappings: TouchMappings,
		coordinator: CoreInputCoordinator,
		namingConvention: ControlNamingConvention,
		menuButtonPlacementChanged: @escaping (CGRect) -> Void,
		screenOffsetChanged: @escaping (TouchMappings.ScreenOffset) -> Void,
	) {
		self.mappings = mappings
		self.coordinator = coordinator
        self.menuButtonPlacementChanged = menuButtonPlacementChanged
        self.screenOffsetChanged = screenOffsetChanged
        
		self.touchControlsSubview = UIView()
		self.touchControlsSubview.translatesAutoresizingMaskIntoConstraints = false
		self.touchControlsSubview.isMultipleTouchEnabled = true

		let haptics = UIImpactFeedbackGenerator(style: .soft)
		self.haptics = haptics
		self.mappings.variants.sort()

		var controls: [ControlState] = []
		var id = -1

		self.directionalPads = mappings.directionals.map { directionalPad in
			id += 1
			controls.append(.init(input: directionalPad.input))
			return switch directionalPad.style {
			case .dpad:
				TouchControlsDirectionalPadView(id: id, directional: directionalPad, haptics: haptics, coordinator: coordinator)
			case .joystick:
				TouchControlsJoystickView(id: id, directional: directionalPad, haptics: haptics, coordinator: coordinator)
			}
		}

		self.buttons = mappings.buttons.map { button in
			id += 1
			controls.append(.init(input: button.input))
			return TouchControlsButtonView(id: id, button: button, namingConvention: namingConvention)
		}

		state = .init()
		state.controls = controls

		super.init(nibName: nil, bundle: nil)

		self.view.addSubview(self.touchControlsSubview)
		NSLayoutConstraint.activate([
			self.touchControlsSubview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			self.touchControlsSubview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			self.touchControlsSubview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			self.touchControlsSubview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
		])

		for button in buttons {
			self.touchControlsSubview.addSubview(button)
		}

		for directionalPad in directionalPads {
			directionalPad.parent = self
			self.touchControlsSubview.addSubview(directionalPad)
		}
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		updateLayout()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		layoutElements()
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		updateLayout()
	}

	func updateLayout() {
		let variantIndex = mappings.variantIndex(for: .init(
			screenBounds: view.window?.screen.bounds.size ?? .zero,
			horizontalClass: traitCollection.horizontalSizeClass,
			verticalClass: traitCollection.verticalSizeClass
		))
		print(variantIndex)
		self.setVariant(variantIndex)
	}

	func setVariant(_ index: Int) {
		guard index != variantIndex, index != -1 else { return }
		print("passed guard", index)
		variantIndex = index
		layoutElements()
	}

	// FIXME: this doesn't run on orientation change sometimes...?
	private func layoutElements() {
		guard variantIndex != -1 else { return }

		let regionSize = self.touchControlsSubview.frame.size
		let layout = self.mappings.variants[variantIndex]

		CATransaction.begin()
		for button in buttons {
			button.frame = .zero
		}
		for directionalPad in directionalPads {
			directionalPad.frame = .zero
		}
		for element in layout.elements {
			let rect = element.rect.resolve(in: regionSize)
			switch element.control {
			case .button(let i):
				self.buttons[i].frame = rect
			case .directional(let i):
				self.directionalPads[i].frame = rect
			}
		}

        menuButtonPlacementChanged(layout.menu.resolve(in: regionSize))
		screenOffsetChanged(layout.screenOffset)
		CATransaction.commit()
	}
}

extension TouchControlsViewController {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let allTouches = event?.allTouches else { return }
		handleTouchDown(touches: allTouches)
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let allTouches = event?.allTouches else { return }
		handleTouchDown(touches: allTouches)
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		handleTouchUp(touches: touches)
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		handleTouchUp(touches: touches)
	}

	func handleTouchDown(touches: Set<UITouch>) {
		CATransaction.begin()
		outer: for button in buttons {
			let currentState = button.isActive
			for touch in touches {
				let location = touch.location(in: self.touchControlsSubview)
				guard button.frame.contains(location) else { continue }
				if !currentState {
					buttonPressed(button: button)
				}
				continue outer
			}
			if currentState {
				buttonReleased(button: button)
			}
		}
		CATransaction.commit()
	}

	func handleTouchUp(touches: Set<UITouch>) {
		CATransaction.begin()
		outer: for button in buttons {
			for touch in touches {
				let location = touch.location(in: self.touchControlsSubview)
				guard button.frame.contains(location) else { continue }
				if button.isActive {
					buttonReleased(button: button)
				}
				continue outer
			}
		}
		CATransaction.commit()
	}

	func buttonPressed(button: TouchControlsButtonView) {
		let (x, y) = button.button.direction.intoValues(isPressed: true)
		state.enqueue(button.button.input, value: .init(x, y), control: button.id, player: 0, deque: coordinator.states)

		button.isActive = true
		self.haptics.impactOccurred()
	}

	func buttonReleased(button: TouchControlsButtonView) {
		state.enqueue(button.button.input, value: .zero, control: button.id, player: 0, deque: coordinator.states)
		button.isActive = false
	}
}

extension TouchMappings.RelativeRect {
	func resolve(in bounds: CGSize, padding: CGFloat = 0.0) -> CGRect {
		let x = switch xOrigin {
        case .left: CGFloat(xOffset) + padding
        case .center: (bounds.width / 2) - CGFloat((size / 2) - xOffset)
        case .right: bounds.width - CGFloat(size + xOffset) - padding
        }
        let y = switch yOrigin {
        case .top: CGFloat(yOffset) + padding
        case .center: (bounds.height / 2) - CGFloat((size / 2) - yOffset)
        case .bottom: bounds.height - CGFloat(size + yOffset) - padding
        }
		let sizeFloat = CGFloat(size)
		return .init(x: x, y: y, width: sizeFloat, height: sizeFloat)
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(PreviewStorage()), .portrait, .landscapeLeft) {
	@Previewable @State var screenOffset: CGSize = .init(width: 0, height: 0)

	PreviewSingleObjectView(GameObject.fetchRequest()) { game, persistence in
		let system = System.gba
        let mappings = InputSourceTouchDescriptor.defaults(for: system)
        
		ZStack {
			Rectangle()
				.foregroundStyle(.gray)
				.aspectRatio(CGFloat(system.screenAspectRatio), contentMode: .fit)
				.offset(screenOffset)
				.ignoresSafeArea()

			TouchControlsView(
				mappings: mappings,
				coordinator: .init(
					maxPlayers: 1,
                    bindings: .init(persistence: persistence, settings: .init(), game: .init(game), system: system),
					reorder: { _ in }
				),
				namingConvention: .nintendo
			) { newOffset in
				screenOffset = .init(
					width: Double(newOffset.x),
					height: Double(newOffset.y)
				)
			} menuButtonPlacementChanged: { newPlacement in
				print("Menu Button", newPlacement)
			}
			.padding()
		}
	}
	.background(Color.black)
	.background(ignoresSafeAreaEdges: .all)
}

#endif
