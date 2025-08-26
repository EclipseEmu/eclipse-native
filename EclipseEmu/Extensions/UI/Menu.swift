import SwiftUI

extension Menu where Label == SwiftUI.Label<Text, Image> {
    init(_ titleKey: LocalizedStringKey, systemImage: String, @ViewBuilder content: () -> Content) {
        self.init(content: content) {
            Label(titleKey, systemImage: systemImage)
        }
    }
}
