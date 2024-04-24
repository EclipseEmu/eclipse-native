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
        .tint(.gray)
        .modify {
            if #available(iOS 16.0, macOS 13.0, *) {
                $0.fontWeight(.semibold)
            } else {
                $0.font(.body.weight(.semibold))
            }
        }
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
    CompatNavigationStack {
        VStack {}
            .toolbar {
                DismissButton()
            }
    }
}
