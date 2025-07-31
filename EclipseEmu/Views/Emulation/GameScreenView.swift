import Metal
import SwiftUI
import EclipseKit

@MainActor
struct GameScreenView<Core: CoreProtocol & SendableMetatype> {
	let coordinator: CoreCoordinator<Core>
}

#if canImport(AppKit)
extension GameScreenView: NSViewRepresentable {
	typealias NSViewType = CustomMetalView

	func makeNSView(context: Context) -> CustomMetalView {
		let view = CustomMetalView()
		Task {
			await self.coordinator.attach(to: view)
		}
		return view
	}

	func updateNSView(_ nsView: CustomMetalView, context: Context) {}
}

final class CustomMetalView: NSView, MetalRenderingSurface {
	private var metalLayer: CAMetalLayer!

	init() {
		super.init(frame: .zero)
		self.wantsLayer = true
		self.metalLayer = self.layer as? CAMetalLayer
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func makeBackingLayer() -> CALayer {
		return CAMetalLayer()
	}

	func getLayer() -> CAMetalLayer? {
		self.metalLayer
	}

	func makeStandardDisplayLink(target: Any, selector: Selector) -> CADisplayLink? {
		self.displayLink(target: target, selector: selector)
	}
}
#elseif canImport(UIKit)
extension GameScreenView: UIViewRepresentable {
	typealias UIViewType = CustomMetalView<Core>

	func makeUIView(context: Context) -> UIViewType {
		let view = UIViewType(coordinator: self.coordinator)
		view.backgroundColor = .blue
		return view
	}

	func updateUIView(_ uiView: UIViewType, context: Context) {}
}

final class CustomMetalView<Core: CoreProtocol & SendableMetatype>: UIView, MetalRenderingSurface {
	weak var coordinator: CoreCoordinator<Core>?
	var metalLayer: CAMetalLayer?

	override class var layerClass: AnyClass {
		return CAMetalLayer.self
	}

	init(coordinator: CoreCoordinator<Core>) {
		super.init(frame: .zero)
		self.coordinator = coordinator
		self.metalLayer = self.layer as? CAMetalLayer
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	func getLayer() -> CAMetalLayer? {
		self.metalLayer
	}

	func makeStandardDisplayLink(target: Any, selector: Selector) -> CADisplayLink? {
		window?.screen.displayLink(withTarget: target, selector: selector)
	}

	override func didMoveToWindow() {
		Task {
			await coordinator?.attach(to: self)
		}
	}
}
#else
#error("Unsupported platform")
#endif
