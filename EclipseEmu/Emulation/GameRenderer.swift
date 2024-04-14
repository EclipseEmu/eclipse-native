import Foundation
import QuartzCore
import Metal

protocol GameRenderer {
    var useAdaptiveSync: Bool { get set }
    func update() throws -> Void
    func render(in renderingSurface: CAMetalLayer) -> Void
}
