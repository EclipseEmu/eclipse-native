import Foundation

extension ExpressibleByIntegerLiteral {
    @inlinable
    init(_ booleanLiteral: BooleanLiteralType) {
        self = booleanLiteral ? 1 : 0
    }
}
