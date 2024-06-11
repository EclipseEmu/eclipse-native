import EclipseKit
import SwiftUI
import UniformTypeIdentifiers

final class PlayGameErrorModel: ObservableObject {
    @Published var error: PlayGameAction.Failure?
    @Published var isPresented: Bool = false
    @Published var isFileImporterOpen = false
    @Published var allowedContentTypes: [UTType] = []

    var game: Game?
    var fileType: PlayGameAction.MissingFile = .none

    init() {}

    @MainActor
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
                    return await self.set(error: .badPermissions, game: game)
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
                return await self.set(error: .unknown(error), game: game)
            }
        }
    }

    func handleRomFile(url: URL) async {
        guard let digest = try? await MD5Hasher().hash(file: url) else {
            return await set(error: .failedToHash, game: game)
        }

        let md5 = digest.hexString()
        guard md5 == game?.md5 else {
            return await set(error: .hashMismatch(.rom, md5, url), game: game)
        }

        replaceRom(url: url, md5: md5)
    }

    func replaceRom(url: URL, md5: String) {
        guard let game else { return }

        let persistence = PersistenceCoordinator.preview
        let romPath = game.romPath(in: persistence)
        guard copyFile(from: url, to: romPath, in: persistence) else { return }

        game.md5 = md5
    }

    func handleSaveStateFile(url: URL) async {}

    private func copyFile(from sourceUrl: URL, to destUrl: URL, in persistence: PersistenceCoordinator) -> Bool {
        guard
            persistence.fileManager.delegate?.fileManager?(
                persistence.fileManager,
                shouldCopyItemAt: sourceUrl,
                to: destUrl
            ) != false
        else {
            return false
        }
        do {
            try persistence.fileManager.copyItem(at: sourceUrl, to: destUrl)
            return true
        } catch {
            return false
        }
    }
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
                            self.errorModel.replaceRom(url: url, md5: md5)
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
