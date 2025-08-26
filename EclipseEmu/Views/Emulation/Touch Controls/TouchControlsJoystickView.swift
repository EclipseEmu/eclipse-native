#if canImport(UIKit)
import UIKit
import EclipseKit

final class TouchControlsJoystickView: UIView, TouchControlsDirectionalViewProtocol {
	let id: Int
	let directional: TouchMappings.Directional
    let stick: UIView
    let background: UIView
	let haptics: UIImpactFeedbackGenerator
	let coordinator: CoreInputCoordinator
	var parent: TouchControlsViewController!

	init(id: Int, directional: TouchMappings.Directional, haptics: UIImpactFeedbackGenerator, coordinator: CoreInputCoordinator) {
		self.id = id
		self.directional = directional
		self.haptics = haptics
		self.coordinator = coordinator

        stick = UIView()
        background = UIView()

        super.init(frame: .zero)

        stick.translatesAutoresizingMaskIntoConstraints = false
        background.translatesAutoresizingMaskIntoConstraints = false

		let backgroundColor = UIColor.white.withAlphaComponent(0.125)
		let borderColor = UIColor.white

        stick.isUserInteractionEnabled = false
		stick.layer.borderWidth = 3
        stick.layer.borderColor = borderColor.cgColor
        stick.layer.backgroundColor = backgroundColor.cgColor

        background.layer.borderWidth = 3
		background.layer.borderColor = UIColor.clear.cgColor
        background.isUserInteractionEnabled = false
        background.translatesAutoresizingMaskIntoConstraints = false
        isMultipleTouchEnabled = false

        self.addSubview(stick)
        self.addSubview(background)
        self.bringSubviewToFront(stick)

        NSLayoutConstraint.activate([
            stick.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.5),
            stick.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.5),
            background.widthAnchor.constraint(equalTo: self.widthAnchor),
            background.heightAnchor.constraint(equalTo: self.heightAnchor),
            stick.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stick.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius = self.frame.size.width / 2
        self.background.layer.cornerRadius = radius
        self.stick.layer.cornerRadius = radius / 2
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

		self.haptics.impactOccurred()
		handleTouchDown(touch: touch)
		UIView.animate(withDuration: 0.3) {
			self.background.layer.borderColor = self.stick.layer.borderColor
			self.background.backgroundColor = self.stick.backgroundColor
		}
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
		handleTouchDown(touch: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		handleTouchUp()
    }

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		handleTouchUp()
	}

	func handleTouchDown(touch: UITouch) {
		let location = touch.location(in: self)
		var x = ((location.x / frame.width) * 2) - 1
		var y = ((location.y / frame.height) * 2) - 1
        
        let xValue = abs(Float32(x)) >= directional.deadzone ? Float32(x) : CoreInputDelta.IGNORE_VALUE
        let yValue = abs(Float32(y)) >= directional.deadzone ? Float32(-y) : CoreInputDelta.IGNORE_VALUE

        parent.state.enqueue(
			directional.input,
			value: .init(xValue, yValue),
			control: self.id,
			player: 0,
			deque: coordinator.states
		)

		let distance = sqrt(pow(x, 2) + pow(y, 2))
		if distance > 0.5 {
			let radians = atan2(y, x)
			x = cos(radians) / 2
			y = sin(radians) / 2
		}
		self.stick.transform = .identity.translatedBy(x: x * frame.width * 0.5, y: y * frame.height * 0.5)
	}

	func handleTouchUp() {
		parent.state.enqueue(directional.input, value: .zero, control: self.id, player: 0, deque: coordinator.states)

		self.stick.transform = .identity
		UIView.animate(withDuration: 0.3) {
			self.background.layer.borderColor = UIColor.clear.cgColor
			self.background.backgroundColor = .clear
		}
	}

    static func transform(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGAffineTransform {
        let distance = sqrt(pow(x, 2) + pow(y, 2))
        var xDistance = x
        var yDistance = y
        if distance > 0.5 {
            let radians = atan2(y, x)
            xDistance = cos(radians) / 2
            yDistance = sin(radians) / 2
        }
        return .identity.translatedBy(x: xDistance * width * 0.5, y: yDistance * height * 0.5)
    }
}
#endif
