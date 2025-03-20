import EclipseKit
import Foundation
import SQLite3

private extension GameSystem {
    static func fromOpenVGDB(string: String) -> GameSystem {
        switch string {
        case "gb": .gb
        case "gbc": .gbc
        case "gba": .gba
        case "nes": .nes
        case "snes": .snes
        default: .unknown
        }
    }

    var openVGDBString: String? {
        switch self {
        case .gb: "gb"
        case .gbc: "gbc"
        case .gba: "gba"
        case .nes: "nes"
        case .snes: "snes"
        default: nil
        }
    }
}

actor OpenVGDB {
    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    static let md5StatementString = "SELECT name, system, region, boxart FROM games WHERE (md5 = ?1) AND (system = ?2);"
    static let searchStatementString =
        "SELECT name, system, region, boxart FROM games WHERE LOWER(name) LIKE LOWER(?1) AND (system = ?2);"

    struct LoadResult: @unchecked Sendable {
        let database: OpaquePointer
        let md5Statement: OpaquePointer
        let searchStatement: OpaquePointer
    }

    enum Failure {
        case unknown
        case failedToOpen
        case missingUrl
        case failedToPrepareMD5Statement
        case failedToPrepareSearchStatement
        case failedToGetCString
        case failedToSetupQuery
    }

    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let system: GameSystem
        let region: String
        let boxart: URL?
    }

    private let queue: DispatchQueue
    private nonisolated(unsafe) let database: OpaquePointer
    private nonisolated(unsafe) let md5Statement: OpaquePointer
    private nonisolated(unsafe) let searchStatement: OpaquePointer

    init(queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)) async throws {
        guard let dbPath = Bundle.main.url(forResource: "openvgdb-min", withExtension: "sqlite") else {
            throw Failure.missingUrl
        }

        let loadResult: LoadResult = try await withUnsafeBlockingThrowingContinuation(queue: queue) { continuation in
            var databasePtr: OpaquePointer?
            guard
                sqlite3_open(dbPath.path, &databasePtr) == SQLITE_OK,
                let databasePtr
            else {
                return continuation.resume(throwing: Failure.failedToOpen)
            }

            var md5Statement: OpaquePointer?
            guard
                sqlite3_prepare_v2(databasePtr, Self.md5StatementString, -1, &md5Statement, nil) == SQLITE_OK,
                let md5Statement
            else {
                return continuation.resume(throwing: Failure.failedToPrepareMD5Statement)
            }

            var searchStatement: OpaquePointer?
            guard
                sqlite3_prepare_v2(databasePtr, Self.searchStatementString, -1, &searchStatement, nil) == SQLITE_OK,
                let searchStatement
            else {
                return continuation.resume(throwing: Failure.failedToPrepareSearchStatement)
            }

            continuation.resume(returning: Self.LoadResult(
                database: databasePtr,
                md5Statement: md5Statement,
                searchStatement: searchStatement
            ))
        }

        self.queue = queue
        database = loadResult.database
        md5Statement = loadResult.md5Statement
        searchStatement = loadResult.searchStatement
    }

    deinit {
        sqlite3_finalize(self.md5Statement)
        sqlite3_finalize(self.searchStatement)
        sqlite3_close(self.database)
    }

    func get(md5: String, system: GameSystem) async throws -> [OpenVGDB.Item] {
        let statementInt = UInt(bitPattern: md5Statement)
        return try await withUnsafeBlockingThrowingContinuation(queue: queue) { continuation in
            let statement = OpaquePointer(bitPattern: statementInt)

            guard
                let md5String = md5.uppercased().cString(using: .ascii),
                let systemString = system.openVGDBString?.cString(using: .ascii)
            else {
                return continuation.resume(throwing: Failure.failedToGetCString)
            }

            guard
                sqlite3_bind_text(statement, 1, md5String, -1, Self.sqliteTransient) == SQLITE_OK,
                sqlite3_bind_text(statement, 2, systemString, -1, Self.sqliteTransient) == SQLITE_OK
            else {
                return continuation.resume(throwing: Failure.failedToSetupQuery)
            }

            continuation.resume(returning: self.getAllRows(statement: statement))
        }
    }

    func search(query: String, system: GameSystem) async throws -> [OpenVGDB.Item] {
        // FIXME: The API uses FTS5, which I am pretty confident the SQLite3 library on iOS/macOS does not come with.
        //  Ideally we'd use FTS in some form, but will probably need to figure out something like FTS3/4,
        //  and if a device doesn't support it then just disable searching for boxart.
        //  See: https://github.com/EclipseEmu/api/blob/main/src/endpoints/boxart.rs

        let queryString = query

        let statementInt = UInt(bitPattern: searchStatement)
        return try await withUnsafeBlockingThrowingContinuation(queue: queue) { continuation in
            let statement = OpaquePointer(bitPattern: statementInt)

            guard
                let queryString = queryString.cString(using: .utf8),
                let systemString = system.openVGDBString?.cString(using: .ascii)
            else {
                return continuation.resume(throwing: Failure.failedToGetCString)
            }

            guard
                sqlite3_bind_text(statement, 1, queryString, -1, Self.sqliteTransient) == SQLITE_OK,
                sqlite3_bind_text(statement, 2, systemString, -1, Self.sqliteTransient) == SQLITE_OK
            else {
                return continuation.resume(throwing: Failure.failedToSetupQuery)
            }

            continuation.resume(returning: self.getAllRows(statement: statement))
        }
    }

    private nonisolated func getAllRows(statement: OpaquePointer!) -> [OpenVGDB.Item] {
        var output: [OpenVGDB.Item] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let nameCStr = sqlite3_column_text(statement, 0),
                let systemCStr = sqlite3_column_text(statement, 1),
                let regionCStr = sqlite3_column_text(statement, 2)
            else {
                continue
            }

            let boxartUrl: URL? = if let boxartCStr = sqlite3_column_text(statement, 3) {
                URL(string: String(cString: boxartCStr))
            } else {
                nil
            }

            output.append(Self.Item(
                name: String(cString: nameCStr),
                system: GameSystem.fromOpenVGDB(string: String(cString: systemCStr)),
                region: String(cString: regionCStr),
                boxart: boxartUrl
            ))
        }

        sqlite3_reset(statement)

        return output
    }
}

extension OpenVGDB.Failure: LocalizedError {
    var failureReason: String? {
        return switch self {
        case .failedToGetCString: "Failed to get C String"
        case .failedToOpen: "Failed to open"
        case .failedToPrepareMD5Statement: "Failed to prepare MD5 statement"
        case .failedToPrepareSearchStatement: "Failed to prepare search statement"
        case .failedToSetupQuery: "Failed to setup the query"
        case .missingUrl: "Missing URL"
        case .unknown: "Unknown"
        }
    }
}
