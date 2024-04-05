import Foundation

extension ExpressibleByIntegerLiteral {
    init(_ booleanLiteral: BooleanLiteralType) {
        self = booleanLiteral ? 1 : 0
    }
}
