import SwiftUI

struct CoverPickerMenu: View {
    @ObservedObject var game: GameObject
    @Binding var coverPickerMethod: CoverPickerMethod?

    var body: some View {
        Menu {
            Button {
                self.coverPickerMethod = .database(game)
            } label: {
                Label("REPLACE_COVER_ART_FROM_DATABASE", systemImage: "cylinder.split.1x2")
            }
            Button {
                self.coverPickerMethod = .photos(game)
            } label: {
                Label("REPLACE_COVER_ART_FROM_PHOTOS", systemImage: "photo.stack")
            }
        } label: {
            Label("REPLACE_COVER_ART", systemImage: "photo")
        }
    }
}
