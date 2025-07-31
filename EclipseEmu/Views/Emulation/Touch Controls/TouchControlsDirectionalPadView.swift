#if canImport(UIKit)
import UIKit
import EclipseKit

final class TouchControlsDirectionalPadView: UIView, TouchControlsDirectionalViewProtocol {
	let id: Int
    let directional: TouchMappings.Directional
	let backgroundLayer: CAGradientLayer
	let shapeLayer: CAShapeLayer
    let borderLayer: CAShapeLayer
    let path: UIBezierPath
	let haptics: UIImpactFeedbackGenerator
	let coordinator: CoreInputCoordinator
	var parent: TouchControlsViewController!

	var lastY = 0.0
	var lastX = 0.0

	init(id: Int, directional: TouchMappings.Directional, haptics: UIImpactFeedbackGenerator, coordinator: CoreInputCoordinator) {
		self.id = id
		self.directional = directional
		self.shapeLayer = .init()
		self.borderLayer = .init()
		self.backgroundLayer = .init()
		self.haptics = haptics
		self.coordinator = coordinator

        path = UIBezierPath()
        let segmentWidth3: CGFloat = 1
        let segmentWidth = segmentWidth3 / 3
        let segmentWidth2 = segmentWidth * 2

        path.move(to: CGPoint(x: segmentWidth, y: 0))
        path.addLine(to: CGPoint(x: segmentWidth2, y: 0))
        path.addLine(to: CGPoint(x: segmentWidth2, y: segmentWidth))
        path.addLine(to: CGPoint(x: segmentWidth3, y: segmentWidth))
        path.addLine(to: CGPoint(x: segmentWidth3, y: segmentWidth2))
        path.addLine(to: CGPoint(x: segmentWidth2, y: segmentWidth2))
        path.addLine(to: CGPoint(x: segmentWidth2, y: segmentWidth3))
        path.addLine(to: CGPoint(x: segmentWidth, y: segmentWidth3))
        path.addLine(to: CGPoint(x: segmentWidth, y: segmentWidth2))
        path.addLine(to: CGPoint(x: 0, y: segmentWidth2))
        path.addLine(to: CGPoint(x: 0, y: segmentWidth))
        path.addLine(to: CGPoint(x: segmentWidth, y: segmentWidth))
        path.addLine(to: CGPoint(x: segmentWidth, y: 0))
        path.close()

        super.init(frame: .zero)
        self.layer.mask = shapeLayer

		let background = UIColor.white.withAlphaComponent(0.125)
		let border = UIColor.white

		borderLayer.lineWidth = 6
        borderLayer.strokeColor = border.cgColor
		borderLayer.fillColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)

		backgroundLayer.frame.size = self.frame.size
		backgroundLayer.colors = [background.cgColor, UIColor.white.cgColor]

		self.layer.addSublayer(borderLayer)
		self.layer.insertSublayer(backgroundLayer, at: 0)

		backgroundLayer.startPoint = .init(x: 0, y: 0)
		backgroundLayer.endPoint = .init(x: 0, y: 0)

		self.backgroundColor = background
	}

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var transform = CGAffineTransform(scaleX: self.bounds.width, y: self.bounds.height)
		let path = unsafe path.cgPath.copy(using: &transform)

		backgroundLayer.frame.size = self.frame.size
		shapeLayer.path = path
        borderLayer.path = path
    }

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else { return }
		handleTouchDown(touch: touch)
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
		let bareX = ((location.x / self.frame.width) * 2) - 1
		let bareY = ((location.y / self.frame.height) * 2) - 1
		let x: CGFloat = bareX >= 0.5 ? 1 : bareX <= -0.5 ? -1 : 0
		let y: CGFloat = bareY >= 0.5 ? 1 : bareY <= -0.5 ? -1 : 0

		if lastX != x || lastY != y {
			parent.state.enqueue(
				directional.input,
				value: .init(Float32(x), Float32(y)),
				control: self.id,
				player: 0,
				deque: coordinator.states
			)

			self.haptics.impactOccurred()
			let startPoint = CGPoint(x: abs(x) * 0.5, y: abs(y) * 0.5)
			let endPoint = CGPoint(x: max(x, 0), y: max(y, 0))
//			self.transform = Self.transform(x: x, y: y)
			self.setGradient(start: startPoint, end: endPoint)
		}
		lastX = x
		lastY = y
	}

	func handleTouchUp() {
		parent.state.enqueue(directional.input, value: .zero, control: self.id, player: 0, deque: coordinator.states)

		setGradient(start: .zero, end: .zero)
//		self.transform = .identity
		lastX = 0
		lastY = 0
	}

	@inlinable
	func setGradient(start: CGPoint, end: CGPoint) {
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		backgroundLayer.startPoint = start
		backgroundLayer.endPoint = end
		CATransaction.commit()
	}

	private static func transform(x: CGFloat, y: CGFloat, deg: CGFloat = 15.0) -> CGAffineTransform {
		var transform = CATransform3DIdentity
		transform.m34 = -1 / 500
		transform = CATransform3DRotate(transform, deg * .pi / 180.0, -y, x, 0)
		return CATransform3DGetAffineTransform(transform)
	}
}
#endif
