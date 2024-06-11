import EclipseKit
import SwiftUI

#if canImport(UIKit)
extension CGRect {
    @inlinable
    func centralDistance(to other: CGPoint) -> CGPoint {
        CGPoint(
            x: max(-1, min((other.x - self.midX) / (self.width / 2), 1)),
            y: max(-1, min((other.y - self.midY) / (self.height / 2), 1))
        )
    }
}

let defaultTouchElements = [
    TouchLayout.Element(
        label: "A",
        style: .circle,
        layout: .init(
            xOrigin: .trailing,
            yOrigin: .trailing,
            x: 16.0,
            y: 149.0,
            width: 75.0, height: 75.0, hidden: false
        ),
        bindings: .init(
            kind: .button,
            inputA: GameInput.faceButtonRight.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "B",
        style: .circle,
        layout: .init(
            xOrigin: .trailing,
            yOrigin: .trailing,
            x: 91.0,
            y: 90.0,
            width: 75.0,
            height: 75.0,
            hidden: false
        ),
        bindings: .init(
            kind: .button,
            inputA: GameInput.faceButtonDown.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "A + B",
        style: .capsule,
        layout: .init(
            xOrigin: .trailing,
            yOrigin: .trailing,
            x: 16.0,
            y: 90.0,
            width: 75.0,
            height: 60.0,
            hidden: true
        ),
        bindings: .init(
            kind: .multiButton,
            inputA: GameInput.faceButtonDown.rawValue | GameInput.faceButtonRight.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "L",
        style: .capsule,
        layout: .init(
            xOrigin: .leading,
            yOrigin: .trailing,
            x: 16.0,
            y: 264.0,
            width: 100.0,
            height: 42.0,
            hidden: false
        ),
        bindings: .init(
            kind: .button,
            inputA: GameInput.shoulderLeft.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "R",
        style: .capsule,
        layout: .init(
            xOrigin: .trailing,
            yOrigin: .trailing,
            x: 16.0,
            y: 264.0,
            width: 100.0,
            height: 42.0,
            hidden: false
        ),
        bindings: .init(
            kind: .button,
            inputA: GameInput.shoulderRight.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "Start",
        style: .capsule,
        layout: .init(
            xOrigin: .trailing,
            yOrigin: .trailing,
            x: 100.0,
            y: 0.0,
            width: 86.0,
            height: 42.0,
            hidden: false
        ),
        bindings: .init(
            kind: .button,
            inputA: GameInput.startButton.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "Select",
        style: .capsule,
        layout: .init(
            xOrigin: .leading,
            yOrigin: .trailing,
            x: 100.0,
            y: 0.0,
            width: 86.0,
            height: 42.0,
            hidden: false
        ),
        bindings: .init(
            kind: .button,
            inputA: GameInput.selectButton.rawValue,
            inputB: .none,
            inputC: .none,
            inputD: .none
        )
    ),
    TouchLayout.Element(
        label: "",
        style: .automatic,
        layout: .init(
            xOrigin: .leading,
            yOrigin: .trailing,
            x: 16.0,
            y: 82.0,
            width: 150.0,
            height: 150.0,
            hidden: false
        ),
        bindings: .init(
            kind: .dpad,
            inputA: GameInput.dpadUp.rawValue,
            inputB: .dpadDown,
            inputC: .dpadLeft,
            inputD: .dpadRight
        )
    )
]

final class TouchControlsController: UIViewController {
    private static let deadZone = 0.25
    private static let borderWidth = 2.0
    private static let borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)

    private let valueChangedHandler: (_ newState: UInt32) -> Void

    private var state: GameInput.RawValue = 0
    private var lockedTouches = [UITouch: (Int, TouchLayout.Element)]()

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let touchControlsSubview = UIView()

    private var touchEls: [TouchLayout.Element] = defaultTouchElements

    init(valueChangedHandler: @escaping (_: UInt32) -> Void) {
        self.valueChangedHandler = valueChangedHandler
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.touchControlsSubview)
        self.touchControlsSubview.translatesAutoresizingMaskIntoConstraints = false
        self.touchControlsSubview.isMultipleTouchEnabled = true
        NSLayoutConstraint.activate([
            self.touchControlsSubview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            self.touchControlsSubview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            self.touchControlsSubview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            self.touchControlsSubview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        let preferredFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let roundedFontDescriptor = preferredFont.fontDescriptor.withDesign(.rounded)
        let roundedFont = if let roundedFontDescriptor {
            UIFont(descriptor: roundedFontDescriptor, size: preferredFont.pointSize)
        } else {
            preferredFont
        }

        for element in self.touchEls {
            let view = UIView()
            view.clipsToBounds = true
            view.backgroundColor = .black

            switch element.bindings.kind {
            case .button, .multiButton:
                let titleLabel = UILabel()
                titleLabel.text = element.label.uppercased()
                titleLabel.font = roundedFont
                titleLabel.textColor = .white
                view.addSubview(titleLabel)
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
                titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

                view.layer.borderWidth = Self.borderWidth
                view.layer.borderColor = Self.borderColor
                view.isHidden = element.layout.hidden
            case .dpad:
                let path = UIBezierPath()
                let segmentWidth3 = element.layout.width
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

                let shapeLayer = CAShapeLayer()
                shapeLayer.frame = view.frame
                shapeLayer.path = path.cgPath
                view.layer.mask = shapeLayer

                let borderLayer = CAShapeLayer()
                borderLayer.path = path.cgPath
                borderLayer.lineWidth = Self.borderWidth * 2
                borderLayer.strokeColor = Self.borderColor
                borderLayer.fillColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
                borderLayer.frame = view.bounds
                view.layer.addSublayer(borderLayer)
            default:
                break
            }
            self.touchControlsSubview.addSubview(view)
        }
    }

    private func layoutElements() {
        guard self.touchControlsSubview.subviews.count >= self.touchEls.count else { return }
        let regionSize = self.touchControlsSubview.frame.size

        for (index, element) in self.touchEls.enumerated() {
            let subview = self.touchControlsSubview.subviews[index]
            subview.frame = CGRect(
                x: element.layout.xOrigin == .leading
                    ? element.layout.x
                    : regionSize.width - (element.layout.x + element.layout.width),
                y: element.layout.yOrigin == .leading
                    ? element.layout.y
                    : regionSize.height - (element.layout.y + element.layout.height),
                width: element.layout.width,
                height: element.layout.height
            )

            switch element.bindings.kind {
            case .button, .multiButton:
                subview.layer.cornerRadius = element.layout.height / 2
            default:
                break
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.layoutElements()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let allTouches = event?.allTouches else { return }
        self.handleTouches(touches: allTouches, isStart: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let allTouches = event?.allTouches else { return }
        self.handleTouches(touches: allTouches, isStart: false)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.handleEndedTouches(touches: touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.handleEndedTouches(touches: touches)
    }

    // FIXME: present some visual indication of input

    private func handleTouches(touches: Set<UITouch>, isStart: Bool) {
        let oldState = self.state
        self.state = 0

        for touch in touches {
            let touchPoint = touch.location(in: self.touchControlsSubview)

            if let (index, element) = self.lockedTouches[touch] {
                let view = self.touchControlsSubview.subviews[index]
                self.touchDown(
                    bindings: element.bindings,
                    view: view,
                    distance: view.frame.centralDistance(to: touchPoint)
                )
                continue
            }

            for (index, element) in self.touchEls.enumerated() {
                let view = self.touchControlsSubview.subviews[index]

                if !view.frame.contains(touchPoint) {
                    continue
                }

                if element.bindings.kind == .joystick || element.bindings.kind == .dpad {
                    guard isStart else { continue }

                    self.lockedTouches[touch] = (index, element)
                    self.touchDown(
                        bindings: element.bindings,
                        view: view,
                        distance: view.frame.centralDistance(to: touchPoint)
                    )
                    continue
                }

                self.state |= element.bindings.inputA
            }
        }

        if self.state & ~oldState > 0 {
            self.feedbackGenerator.impactOccurred()
        }

        self.valueChangedHandler(self.state)
    }

    private func handleEndedTouches(touches: Set<UITouch>) {
        for touch in touches {
            if let (_, element) = self.lockedTouches[touch] {
                self.lockedTouches.removeValue(forKey: touch)
//                let view = self.touchControlsSubview.subviews[i]
                self.state &= ~(
                    element.bindings.inputA |
                        element.bindings.inputB.rawValue |
                        element.bindings.inputC.rawValue |
                        element.bindings.inputD.rawValue)
                self.valueChangedHandler(self.state)
                continue
            }

            let touchPoint = touch.location(in: self.touchControlsSubview)

            for (index, element) in self.touchEls.enumerated() {
                let view = self.touchControlsSubview.subviews[index]
                if !view.frame.contains(touchPoint) {
                    continue
                }
                self.state &= ~(
                    element.bindings.inputA |
                        element.bindings.inputB.rawValue |
                        element.bindings.inputC.rawValue |
                        element.bindings.inputD.rawValue)
            }
        }
        self.valueChangedHandler(self.state)
    }

    private func touchDown(bindings: TouchLayout.Bindings, view: UIView, distance: CGPoint) {
        self.state |=
            (UInt32(distance.y <= -Self.deadZone) * bindings.inputA) |
            (UInt32(distance.y >= Self.deadZone) * bindings.inputB.rawValue) |
            (UInt32(distance.x <= -Self.deadZone) * bindings.inputC.rawValue) |
            (UInt32(distance.x >= Self.deadZone) * bindings.inputD.rawValue)
    }
}

struct TouchControlsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = TouchControlsController
    var callback: (UInt32) -> Void

    init(_ callback: @escaping (UInt32) -> Void) {
        self.callback = callback
    }

    func makeUIViewController(context: Context) -> TouchControlsController {
        return TouchControlsController(valueChangedHandler: self.callback)
    }

    func updateUIViewController(_ uiViewController: TouchControlsController, context: Context) {}
}

#Preview {
    struct DemoView: View {
        @State var value: UInt32 = 0

        var body: some View {
            ZStack {
                Text("\(value)")
                TouchControlsView { value = $0 }
            }
        }
    }

    return DemoView()
}
#endif
