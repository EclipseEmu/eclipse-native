import Foundation

extension Data {
    init(asyncContentsOf url: URL) async throws {
        let (data, _) = try await URLSession.shared.data(from: url)
        self = data
    }
}
