import QuartzCore

struct MetalDisplayLink: ~Copyable {
    let layer: CAMetalLayer
    let displayLink: any DisplayLinkProtocol

    deinit {
        displayLink.isPaused = true
        displayLink.remove(from: .current, forMode: .default)
    }
}

protocol DisplayLinkProtocol: NSObjectProtocol {
    var isPaused: Bool { get set }
    var preferredFrameRateRange: CAFrameRateRange { get set }

    func add(to runloop: RunLoop, forMode mode: RunLoop.Mode)
    func remove(from runloop: RunLoop, forMode mode: RunLoop.Mode)
    func invalidate()
}

@MainActor
protocol MetalRenderingSurface {
	func getLayer() -> CAMetalLayer?
	func makeStandardDisplayLink(target: Any, selector: Selector) -> CADisplayLink?
}

extension CADisplayLink: DisplayLinkProtocol {}

@available(iOS 17.0, *)
extension CAMetalDisplayLink: DisplayLinkProtocol {}

