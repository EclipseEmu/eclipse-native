import Metal
import SwiftUI

struct GameScreenView {
    var model: EmulationViewModel

    class Coordinator: NSObject {
        var parent: GameScreenView

        init(_ parent: GameScreenView) {
            self.parent = parent
            super.init()
        }

        @MainActor @inlinable
        func surfaceCreated(surface: CAMetalLayer) {
            self.parent.model.renderingSurfaceCreated(surface: surface)
        }
    }
}

#if canImport(AppKit)
extension GameScreenView: NSViewRepresentable {
    typealias NSViewType = CustomMetalView

    func makeNSView(context: Context) -> CustomMetalView {
        let view = CustomMetalView()
        view.delegate = context.coordinator
        context.coordinator.surfaceCreated(surface: view.metalLayer)
        return view
    }

    func updateNSView(_ nsView: CustomMetalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class CustomMetalView: NSView {
    var delegate: GameScreenView.Coordinator?
    var metalLayer: CAMetalLayer!

    init() {
        super.init(frame: .zero)
        self.wantsLayer = true
        self.metalLayer = self.layer as? CAMetalLayer
        self.metalLayer?.magnificationFilter = .nearest
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeBackingLayer() -> CALayer {
        return CAMetalLayer()
    }
}

#elseif canImport(UIKit)
extension GameScreenView: UIViewRepresentable {
    typealias UIViewType = CustomMetalView

    func makeUIView(context: Context) -> CustomMetalView {
        let view = CustomMetalView()
        view.delegate = context.coordinator
        if let layer = view.metalLayer {
            context.coordinator.surfaceCreated(surface: layer)
        }
        return view
    }

    func updateUIView(_ uiView: CustomMetalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

class CustomMetalView: UIView {
    var delegate: GameScreenView.Coordinator?
    var metalLayer: CAMetalLayer?

    override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    init() {
        super.init(frame: .zero)
        self.metalLayer = self.layer as? CAMetalLayer
        self.metalLayer?.magnificationFilter = .nearest
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#else
#error("Unsupported platform")
#endif
