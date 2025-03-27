import PhotosUI
import SwiftUI

@available(*, deprecated, renamed: "OldView", message: "this is an old view, do not use.")
struct ReplaceBoxartMenu: View {
    @Binding var isDatabaseOpen: Bool
    @Binding var isPhotosOpen: Bool

    var body: some View {
        Menu {
            Button {
                isPhotosOpen = true
            } label: {
                Label("From Photos", systemImage: "photo.stack")
            }

            Button {
                isDatabaseOpen = true
            } label: {
                Label("From Database", systemImage: "cylinder.split.1x2")
            }
        } label: {
            Label("Replace Box Art", systemImage: "photo")
        }
    }
}

@available(iOS 18.0, macOS 15.0, *)
#Preview {
    @Previewable @State var isDatabaseOpen = false
    @Previewable @State var isPhotosOpen = false

    ReplaceBoxartMenu(
        isDatabaseOpen: $isDatabaseOpen,
        isPhotosOpen: $isPhotosOpen
    )
}
