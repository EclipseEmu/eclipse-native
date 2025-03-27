import SwiftUI

struct CoverPickerMenu: View {
    @ObservedObject var game: Game
    @Binding var coverPickerMethod: CoverPickerMethod?

    var body: some View {
        Menu {
            Button {
                self.coverPickerMethod = .database(game)
            } label: {
                Label("From Database", systemImage: "cylinder.split.1x2")
            }
            Button {
                self.coverPickerMethod = .photos(game)
            } label: {
                Label("From Photos", systemImage: "photo.stack")
            }
        } label: {
            Label("Replace Cover Art", systemImage: "photo")
        }
    }
}
