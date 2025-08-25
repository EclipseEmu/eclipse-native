import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct FileImportType: Sendable {
    let types: [UTType]
    let allowsMultipleSelection: Bool
    let completion: @Sendable (Result<[URL], any Error>) -> Void

    static let `default` = Self(
        types: [],
        allowsMultipleSelection: false,
        completion: { _ in }
    )

    static func roms(
        multiple: Bool = false,
        completion: @Sendable @escaping (Result<[URL], any Error>) -> Void
    ) -> Self {
        .init(types: UTType.allRomFileTypes, allowsMultipleSelection: multiple, completion: completion)
    }
    
    static func saveState(completion: @Sendable @escaping (Result<[URL], any Error>) -> Void) -> Self {
        .init(types: [.saveState], allowsMultipleSelection: false, completion: completion)
    }

    static func saves(completion: @Sendable @escaping (Result<[URL], any Error>) -> Void) -> Self {
        .init(types: [.save], allowsMultipleSelection: false, completion: completion)
    }
}

struct MultiFileImporterViewModifier: ViewModifier {
    @Binding var type: FileImportType?

    func body(content: Content) -> some View {
        let type = self.type ?? .default
        content
            .fileImporter(
                isPresented: .isSome($type),
                allowedContentTypes: type.types,
                allowsMultipleSelection: type.allowsMultipleSelection,
                onCompletion: type.completion
            )
    }
}

extension View {
    func multiFileImporter(_ type: Binding<FileImportType?>) -> some View {
        modifier(MultiFileImporterViewModifier(type: type))
    }
}
