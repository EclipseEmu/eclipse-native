import SwiftUI
import UniformTypeIdentifiers

struct SaveFileDocument: FileDocument {
    static let readableContentTypes = [UTType.save]
    let data: URL
    let fileName: String?

    private struct EmptyError: Error {}

    init(url: URL, fileName: String) {
        self.data = url
        self.fileName = fileName
    }

    init(configuration: ReadConfiguration) throws {
        throw EmptyError()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let wrapper = try FileWrapper(url: data)
        wrapper.preferredFilename = self.fileName
        return wrapper
    }
}
