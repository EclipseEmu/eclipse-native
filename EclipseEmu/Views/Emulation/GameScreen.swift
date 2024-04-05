import SwiftUI
import MetalKit

struct EmulationGameScreen {
    var emulation: GameCoreCoordinator
}

#if os(macOS)
extension EmulationGameScreen: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer = emulation.renderingSurface
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#elseif os(iOS)
extension EmulationGameScreen: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ResizingSublayerView {
        let view = ResizingSublayerView()
        view.layer = emulation.renderingSurface
        return view
    }
    
    func updateUIViewController(_ uiViewController: ResizingSublayerView, context: Context) {}
    
    class ResizingSublayerView: UIViewController {
        var layer: CALayer? { 
            didSet {
                if let layer {
                    layer.frame = self.view.bounds
                    self.view.layer.addSublayer(layer)
                }
            }
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            guard let layer = self.layer else { return }
            layer.frame = self.view.bounds
        }
    }
}
#endif
