import SwiftUI

struct DismissButton: View {
    @Environment(\.dismiss) var dismiss

    static var placement: ToolbarItemPlacement = .cancellationAction

    var body: some View {
        Button {
            dismiss()
        } label: {
            Label("Cancel", systemImage: "xmark")
        }
        .padding(8.0)
        .imageScale(.small)
        .labelStyle(.iconOnly)
        .background(.quaternary)
        .tint(.secondary)
        .font(.body.weight(.semibold))
        .clipShape(Circle())
    }
}

#Preview {
    CompatNavigationStack {
        VStack {}
            .toolbar {
                DismissButton()
            }
    }
}
