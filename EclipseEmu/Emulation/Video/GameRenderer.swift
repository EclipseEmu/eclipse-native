import Foundation
import QuartzCore
import Metal

protocol GameRenderer {
    func update() throws -> Void
    func render(in renderingSurface: CAMetalLayer) -> Void
}
