import SwiftUI

struct FullWidthLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
            configuration.title
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}
