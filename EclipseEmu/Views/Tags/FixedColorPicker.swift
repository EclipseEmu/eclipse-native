import SwiftUI

struct FixedColorPicker: View {
    @Binding var selection: TagColor

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 16.0) {
                ForEach(TagColor.allCases, id: \.self) { color in
                    Button {
                        withAnimation {
                            selection = color
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 2)
                                .frame(width: 36, height: 36)
                                .opacity(selection == color ? 1.0 : 0.0)
                            Circle()
                                .padding(selection == color ? 3.0 : 0.0)
                                .frame(width: 36, height: 36)
                        }
                        .foregroundStyle(color.color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding([.horizontal, .vertical])
        }
    }
}

@available(iOS 18.0, macOS 14.0, *)
#Preview {
    @Previewable @State var tagColor: TagColor = .blue
    FixedColorPicker(selection: $tagColor)
}
