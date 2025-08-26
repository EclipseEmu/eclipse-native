import SwiftUI

struct NoWrapLabeledContentStyle: LabeledContentStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            configuration.content
        }
    }
}

extension LabeledContentStyle where Self == NoWrapLabeledContentStyle {
    @MainActor static var noWrap: NoWrapLabeledContentStyle { .init() }
}
