import Foundation

extension Data {
    init(asyncContentsOf url: URL) async throws {
        let stream = try FileStream(url: url, mode: .readOnly)
        self = try await Data(stream.readAll())
        stream.close()
    }
}
