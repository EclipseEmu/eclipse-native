import PhotosUI
import SwiftUI

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

#Preview {
    ReplaceBoxartMenu(
        isDatabaseOpen: .constant(false),
        isPhotosOpen: .constant(false)
    )
}
