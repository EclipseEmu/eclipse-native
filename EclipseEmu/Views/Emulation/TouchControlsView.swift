import SwiftUI
import EclipseKit

#if canImport(UIKit)
fileprivate let borderWidth = 2.0
fileprivate let borderColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)

final class TouchControlsController: UIViewController {
    var valueChangedHandler: ((_ newState: UInt32) -> Void)?

    private var state: GameInput.RawValue = 0
    private var feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private var touchControlsSubview = UIView()
    
    var menuButtonLayout: TouchLayout.ElementDisplay = .init(xOrigin: .leading, yOrigin: .trailing, x: 16.0, y: 0.0, width: 42.0, height: 42.0, hidden: false)
    var touchEls: [TouchLayout.Element] = [
        TouchLayout.Element(
            label: "A",
            style: .circle,
            layout: .init(xOrigin: .trailing, yOrigin: .trailing, x: 16.0, y: 149.0, width: 75.0, height: 75.0, hidden: false),
            bindings: .init(kind: .button, inputA: GameInput.faceButtonRight.rawValue, inputB: .none, inputC: .none, inputD: .none)
        ),
        TouchLayout.Element(
            label: "B",
            style: .circle,
            layout: .init(xOrigin: .trailing, yOrigin: .trailing, x: 91.0, y: 90.0, width: 75.0, height: 75.0, hidden: false),
            bindings: .init(kind: .button, inputA: GameInput.faceButtonDown.rawValue, inputB: .none, inputC: .none, inputD: .none)
        ),
        TouchLayout.Element(
            label: "L",
            style: .capsule,
            layout: .init(xOrigin: .leading, yOrigin: .trailing, x: 16.0, y: 264.0, width: 100.0, height: 42.0, hidden: false),
            bindings: .init(kind: .button, inputA: GameInput.faceButtonRight.rawValue, inputB: .none, inputC: .none, inputD: .none)
        ),
        TouchLayout.Element(
            label: "R",
            style: .capsule,
            layout: .init(xOrigin: .trailing, yOrigin: .trailing, x: 16.0, y: 264.0, width: 100.0, height: 42.0, hidden: false),
            bindings: .init(kind: .button, inputA: GameInput.faceButtonDown.rawValue, inputB: .none, inputC: .none, inputD: .none)
        ),
        TouchLayout.Element(
            label: "Start",
            style: .capsule,
            layout: .init(xOrigin: .trailing, yOrigin: .trailing, x: 100.0, y: 0.0, width: 86.0, height: 42.0, hidden: false),
            bindings: .init(kind: .button, inputA: GameInput.startButton.rawValue, inputB: .none, inputC: .none, inputD: .none)
        ),
        TouchLayout.Element(
            label: "Select",
            style: .capsule,
            layout: .init(xOrigin: .leading, yOrigin: .trailing, x: 100.0, y: 0.0, width: 86.0, height: 42.0, hidden: false),
            bindings: .init(kind: .button, inputA: GameInput.selectButton.rawValue, inputB: .none, inputC: .none, inputD: .none)
        ),
        TouchLayout.Element(
            label: "",
            style: .automatic,
            layout: .init(xOrigin: .leading, yOrigin: .trailing, x: 16.0, y: 82.0, width: 150.0, height: 150.0, hidden: false),
            bindings: .init(kind: .dpad, inputA: GameInput.dpadUp.rawValue, inputB: .dpadDown, inputC: .dpadLeft, inputD: .dpadRight)
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.touchControlsSubview)
        self.touchControlsSubview.translatesAutoresizingMaskIntoConstraints = false
        self.touchControlsSubview.isMultipleTouchEnabled = true
        NSLayoutConstraint.activate([
            touchControlsSubview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            touchControlsSubview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            touchControlsSubview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            touchControlsSubview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let preferredFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        let roundedFontDescriptor = preferredFont.fontDescriptor.withDesign(.rounded);
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
                
                view.layer.borderWidth = borderWidth
                view.layer.borderColor = borderColor
                break
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
                borderLayer.lineWidth = borderWidth * 2
                borderLayer.strokeColor = borderColor
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
        
        for (i, element) in self.touchEls.enumerated() {
            let x = element.layout.xOrigin == .leading
                ? element.layout.x
                : regionSize.width - (element.layout.x + element.layout.width)
            let y = element.layout.yOrigin == .leading
                ? element.layout.y
                : regionSize.height - (element.layout.y + element.layout.height)
            
            let subview = self.touchControlsSubview.subviews[i]
            subview.frame = .init(x: x, y: y, width: element.layout.width, height: element.layout.height)
            
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
        self.handleTouches(touches: allTouches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let allTouches = event?.allTouches else { return }
        self.handleTouches(touches: allTouches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.handleEndedTouches(touches: touches)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.handleEndedTouches(touches: touches)
    }
    
    private func handleTouches(touches: Set<UITouch>) {
        self.state = 0
        
        for touch in touches {
            let touchPoint = touch.location(in: self.touchControlsSubview)
            for (i, element) in self.touchEls.enumerated() {
                let view = self.touchControlsSubview.subviews[i]
                if !view.frame.contains(touchPoint) {
                    continue
                }
                
                self.state |= element.bindings.inputA
                self.valueChangedHandler?(self.state)
            }
        }
    }
    
    private func handleEndedTouches(touches: Set<UITouch>) {
        for touch in touches {
            let touchPoint = touch.location(in: self.touchControlsSubview)
            for (i, element) in self.touchEls.enumerated() {
                let view = self.touchControlsSubview.subviews[i]
                if !view.frame.contains(touchPoint) {
                    continue
                }
                
                self.state &= ~element.bindings.inputA
                self.valueChangedHandler?(self.state)
            }
        }
    }
}

struct TouchControlsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = TouchControlsController
    var callback: (UInt32) -> Void
    
    init(_ callback: @escaping (UInt32) -> Void) {
        self.callback = callback
    }
    
    func makeUIViewController(context: Context) -> TouchControlsController {
        let vc = TouchControlsController()
        vc.valueChangedHandler = self.callback
        return vc
    }
    
    func updateUIViewController(_ uiViewController: TouchControlsController, context: Context) {}
}


#Preview {
    struct DemoView: View {
        @State var foo: UInt32 = 0
        
        var body: some View {
            ZStack {
                Text("\(foo)")
                TouchControlsView { newValue in foo = newValue }
            }
        }
    }
    
    return DemoView()
}
#endif
