import SwiftUI
import PhotosUI

struct CoverPickerViewModifier: ViewModifier {
    @EnvironmentObject private var persistence: Persistence

    @Binding var method: CoverPickerMethod?
    @Binding private var photosSheet: Game?
    @Binding private var databaseSheet: Game?

    init(presenting method: Binding<CoverPickerMethod?>) {
        self._method = method
        self._photosSheet = .init(get: {
            if case .photos(let game) = method.wrappedValue { game } else { nil }
        }, set: { game in
            method.wrappedValue = if let game {
                .photos(game)
            } else {
                nil
            }
        })
        self._databaseSheet = .init(get: {
            if case .database(let game) = method.wrappedValue { game } else { nil }
        }, set: { game in
            method.wrappedValue = if let game {
                .database(game)
            } else {
                nil
            }
        })
    }

    func body(content: Content) -> some View {
        content
            .photosImporter(isPresented: .isSome($photosSheet), onSelection: handleImageSelected)
            .sheet(item: $method) { mode in
                NavigationStack {
                    CoverPickerDatabaseView(game: mode.game)
                }
            }
    }

    func handleImageSelected(selection: Result<URL, any Error>) {
        guard let game = photosSheet, case .success(let url) = selection else {
            return
        }
        Task {
            do {
                try await persistence.objects.replaceCoverArt(game: .init(game), copying: url)
            } catch {
                // FIXME: Surface error
                print(error)
            }
        }
    }
}

extension View {
    func coverPicker(presenting method: Binding<CoverPickerMethod?>) -> some View {
        self.modifier(CoverPickerViewModifier(presenting: method))
    }
}
