import SwiftUI

struct GameItemCheckbox: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(isSelected ? AnyShapeStyle(.selection) : AnyShapeStyle(.background))
            Image(systemName: "checkmark")
                .foregroundStyle(.white)
                .imageScale(.small)
                .frame(width: 24, height: 24)
                .opacity(Double(isSelected))
            Circle()
                .stroke(lineWidth: 2)
                .foregroundStyle(isSelected ? .white.opacity(1) : .gray.opacity(0.8))
        }
        .compositingGroup()
        .frame(width: 24, height: 24)
    }
}
