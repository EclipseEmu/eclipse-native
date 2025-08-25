import SwiftUI

struct GameErrorHandlerViewModifier: ViewModifier {
    @ObservedObject var game: GameObject
    @Binding var error: GameViewError?
    @Binding var fileImportRequest: FileImportRequest?
    @Binding var isReplaceRomConfirmationOpen: Bool

    @EnvironmentObject private var persistence: Persistence

    func body(content: Content) -> some View {
        content
            .confirmationDialog("REPLACE_ROM", isPresented: $isReplaceRomConfirmationOpen) {
                Button("CANCEL", role: .cancel) {}
                Button("OK", action: self.replaceROM)
            } message: {
                Text("REPLACE_ROM_MESSAGE")
            }
            .alert(isPresented: .isSome($error), error: error) {
            switch error {
            case .playbackError(let playbackError):
                switch playbackError {
                case .hashMismatch(let file, let hash, let url):
                    CancelButton(action: noop)
                    switch file {
                    case .rom:
                        Button("REPLACE_ANYWAYS", role: .destructive) {
                            self.resolveHashMismatch(newHash: hash, sourceURL: url)
                        }
                    default: EmptyView()
                    }
                case .missingFile(let file):
                    switch file {
                    case .saveState(let box):
                        CancelButton(action: noop)
                        Button("SELECT_FILE") {
                            replaceSaveState(saveState: box)
                        }
                    case .rom:
                        CancelButton(action: noop)
                        Button("SELECT_FILE", action: replaceROM)
                    default:
                        ConfirmButton("OK", action: noop)
                    }
                default:
                    ConfirmButton("OK", action: noop)
                }
            default:
                ConfirmButton("OK", action: noop)
            }
        }
    }
    
    private func noop() {}
    
    private func replaceSaveState(saveState: ObjectBox<SaveStateObject>) {
        fileImportRequest = .saveState { result in
            Task { @MainActor in
                await saveStateImported(result, saveState: saveState)
            }
        }
    }
    
    private func replaceROM() {
        guard let fileType = game.system.fileType else { return}
        fileImportRequest = .init(types: [fileType], allowsMultipleSelection: false, completion: romFileImported)
    }
    
    private nonisolated func romFileImported(_ result: Result<[URL], any Error>) {
        Task {
            do {
                let (game, sha1, destinationPath) = await MainActor.run {
                    (ObjectBox(self.game), self.game.sha1, self.game.romPath)
                }

                guard let sourceURL = try result.get().first, let expectedHash = sha1 else { return }

                let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if doStopAccessing {
                        sourceURL.stopAccessingSecurityScopedResource()
                    }
                }

                let actualHash = try await persistence.files.sha1(for: sourceURL)

                guard expectedHash == actualHash else {
                    throw GameViewError.playbackError(.hashMismatch(.rom(game), actualHash, sourceURL))
                }

                try await persistence.files.overwrite(copying: .other(sourceURL), to: destinationPath)
            } catch let error as GameViewError {
                await MainActor.run {
                    self.error = error
                }
            } catch {
                await MainActor.run {
                    self.error = .replaceROM(error)
                }
            }
        }
        
    }
    
    @MainActor
    private func saveStateImported(
        _ result: Result<[URL], any Error>,
        saveState: ObjectBox<SaveStateObject>
    ) async {
        guard
            let saveState = saveState.tryGet(in: persistence.mainContext),
            let sourceURL = try? result.get().first
        else {
            return
        }
        
        do {
            try await persistence.files.overwrite(
                copying: .other(sourceURL),
                to: saveState.path
            )
        } catch {
            self.error = .replaceSaveState(error)
        }
    }

    @MainActor
    private func resolveHashMismatch(newHash: String, sourceURL: URL) {
        Task {
            do {
                let doStopAccessing = sourceURL.startAccessingSecurityScopedResource()
                defer {
                    if doStopAccessing {
                        sourceURL.stopAccessingSecurityScopedResource()
                    }
                }

                if let oldPath = self.game.sha1, await persistence.objects.canDeleteRom(sha1: oldPath) {
                    try? await persistence.files.delete(at: self.game.romPath)
                }

                let fileExtension = sourceURL.fileExtension()
                try await persistence.objects.updateHash(newHash, for: .init(game))
                try await persistence.files.overwrite(copying: .other(sourceURL), to: .rom(fileName: newHash, fileExtension: fileExtension))
            } catch {
                self.error = .replaceROM(error)
            }
        }
    }
}

extension View {
    func gameErrorHandler(
        game: GameObject,
        error: Binding<GameViewError?>,
        fileImportRequest: Binding<FileImportRequest?>,
        isReplaceRomConfirmationOpen: Binding<Bool> = .constant(false)
    ) -> some View {
        self.modifier(GameErrorHandlerViewModifier(
            game: game,
            error: error,
            fileImportRequest: fileImportRequest,
            isReplaceRomConfirmationOpen: isReplaceRomConfirmationOpen
        ))
    }
}
