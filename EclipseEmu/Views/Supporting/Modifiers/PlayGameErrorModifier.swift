import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class PlayGameErrorModel: ObservableObject {
    @Published var error: PlayGameAction.Failure?
    @Published var isPresented: Bool = false
    @Published var isFileImporterOpen = false
    @Published var allowedContentTypes: [UTType] = []

    var game: Game?
    var fileType: PlayGameAction.MissingFile = .none

    func set(error: PlayGameAction.Failure, game: Game?) {
        self.error = error
        self.game = game
        isPresented = true
    }

    func selectFile(_ kind: PlayGameAction.MissingFile) {
        guard kind != .none else { return }
        fileType = kind
        allowedContentTypes = if let fileType = game?.system.fileType {
            [fileType]
        } else {
            []
        }
        isFileImporterOpen = true
    }

    func onFileCompletion(_ result: Result<URL, any Error>) {
        Task {
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    return self.set(error: .badPermissions, game: game)
                }
                defer { url.stopAccessingSecurityScopedResource() }

                switch self.fileType {
                case .none:
                    break
                case .rom:
                    await handleRomFile(url: url)
                case .saveState:
                    await handleSaveStateFile(url: url)
                }
            case .failure(let error):
                return self.set(error: .unknown(error), game: game)
            }
        }
    }

    func handleRomFile(url: URL) async {
        guard let md5 = try? await FileSystem.shared.md5(for: url) else {
            return set(error: .failedToHash, game: game)
        }

        guard md5 == game?.md5 else {
            return set(error: .hashMismatch(.rom, md5, url), game: game)
        }


        await replaceRom(url: url, md5: md5)
    }

    func replaceRom(url: URL, md5: String) async {
        guard let game else { return }

        do {
            try await FileSystem.shared.overwrite(copying: .other(url), to: game.romPath)
            game.md5 = md5
        } catch {
            return set(error: .failedToReplaceRom, game: game)
        }
    }

    func handleSaveStateFile(url: URL) async {}
}

struct PlayGameErrorHandlerModifier: ViewModifier {
    @ObservedObject var errorModel: PlayGameErrorModel

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorModel.isPresented, error: errorModel.error) {
                Button("Cancel", role: .cancel) {}
                switch errorModel.error {
                case .hashMismatch(let kind, let md5, let url):
                    if kind == .rom {
                        Button("Use Anyway", role: .destructive) {
                            Task {
                                await self.errorModel.replaceRom(url: url, md5: md5)
                            }
                        }
                    }
                case .missingFile(let kind):
                    Button("Select File") {
                        self.errorModel.selectFile(kind)
                    }
                default: EmptyView()
                }
            }
            .fileImporter(
                isPresented: $errorModel.isFileImporterOpen,
                allowedContentTypes: errorModel.allowedContentTypes,
                onCompletion: errorModel.onFileCompletion
            )
    }
}

extension View {
    func playGameErrorAlert(errorModel: PlayGameErrorModel) -> some View {
        modifier(PlayGameErrorHandlerModifier(errorModel: errorModel))
    }
}
