import SwiftUI

struct DismissButton: View {
    @Environment(\.dismiss) var dismiss
    
    static var placement: ToolbarItemPlacement = {
        #if os(macOS)
        .primaryAction
        #elseif os(iOS)
        .topBarTrailing
        #else
        #error("unimplemented")
        #endif
    }()
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Label("Close", systemImage: "xmark")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .fontWeight(.semibold)
        .tint(.gray)
        .modify {
            if #available(iOS 17.0, macOS 14.0, *) {
                $0.buttonBorderShape(.circle)
            } else {
                $0.clipShape(Circle())
            }
        }
    }
}

#Preview {
    NavigationStack {
        VStack {}
            .toolbar {
                DismissButton()
            }
    }
}
