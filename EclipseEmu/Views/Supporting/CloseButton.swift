import SwiftUI

struct CloseButton: View {
    var dismissAction: DismissAction?
    
    var body: some View {
        Button {
            self.dismissAction?()
        } label: {
            Label("Close Game", systemImage: "xmark")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .fontWeight(.semibold)
        .tint(.gray)
        .modify {
            if #available(iOS 17.0, macOS 14.0, *) {
                $0.buttonBorderShape(.circle)
            } else {
                $0
            }
        }
    }
}

#Preview {
    CloseButton(dismissAction: nil)
}
