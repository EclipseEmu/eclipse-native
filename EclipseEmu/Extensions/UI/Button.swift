import SwiftUI

extension Button {
    init(action: DismissAction, label: () -> Label) {
        self = .init(action: action.callAsFunction, label: label)
    }
}

extension Button where Label == Text {
    init(_ title: LocalizedStringKey, role: ButtonRole? = nil, action: DismissAction) {
        self = .init(title, role: role, action: action.callAsFunction)
    }
}
