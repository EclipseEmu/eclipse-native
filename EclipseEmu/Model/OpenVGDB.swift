import Foundation
import SQLite3
import EclipseKit

enum OpenVGDBError: LocalizedError {
    case missingDatabaseFile
    case failedToOpenDatabase
    case failedToPrepareSha1Statement
    case failedToPrepareSearchStatement
    case failedToGetCString
    case failedToSetupQuery
    case failedToPrepareStatement

    var errorDescription: String? {
        switch self {
        case .missingDatabaseFile:
            return "Missing database file."
        case .failedToOpenDatabase:
            return "Failed to open database."
        case .failedToPrepareSha1Statement:
            return "Failed to prepare SHA1 statement."
        case .failedToPrepareSearchStatement:
            return "Failed to prepare search statement."
        case .failedToPrepareStatement:
            return "Failed to prepare search statement."
        case .failedToGetCString:
            return "Failed to get C string."
        case .failedToSetupQuery:
            return "Failed to setup query"
        }
    }
}

struct OpenVGDBItem: Sendable, Identifiable {
    let id = UUID()
    let name: String
    let system: GameSystem
    let region: String
    let cover: URL?
}

private extension GameSystem {
    init(openVGDBString: String) {
        self = switch openVGDBString {
        case "GB": .gb
        case "GBA": .gba
        case "GBC": .gbc
        case "NES": .nes
        case "SNES": .snes
        default: .unknown
        }
    }

    var openVGDBString: String? {
        switch self {
        case .gb: "GB"
        case .gba: "GBA"
        case .gbc: "GBC"
        case .nes: "NES"
        case .snes: "SNES"
        default: nil
        }
    }
}

final actor OpenVGDB {
    static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private static let sha1StatementString =
    "SELECT name, system, region, cover FROM games WHERE (sha1 = ?) AND (system = ?);"
    private static let searchStatementString =
    "SELECT * FROM games WHERE cover IS NOT NULL AND name MATCH(?) AND (system = ?) ORDER BY RANK LIMIT 50;"

    private let database: UnsafeSendable<OpaquePointer>
    private let sha1Statement: UnsafeSendable<OpaquePointer>
    private let searchStatement: UnsafeSendable<OpaquePointer>

    init() throws(OpenVGDBError) {
        guard let dbPath = Bundle.main.url(forResource: "openvgdb-min", withExtension: "sqlite") else {
            throw .missingDatabaseFile
        }

        var databasePtr: OpaquePointer?
        guard
            sqlite3_open(dbPath.path, &databasePtr) == SQLITE_OK,
            let databasePtr
        else {
            throw .failedToOpenDatabase
        }

        var sha1Statment: OpaquePointer?
        guard
            sqlite3_prepare_v2(databasePtr, Self.sha1StatementString, -1, &sha1Statment, nil) == SQLITE_OK,
            let sha1Statment
        else {
            throw .failedToPrepareSha1Statement
        }

        var searchStatement: OpaquePointer?
        guard
            sqlite3_prepare_v2(databasePtr, Self.searchStatementString, -1, &searchStatement, nil) == SQLITE_OK,
            let searchStatement
        else {
            throw .failedToPrepareSearchStatement
        }

        self.database = .init(databasePtr)
        self.sha1Statement = .init(sha1Statment)
        self.searchStatement = .init(searchStatement)
    }

    deinit {
        sqlite3_finalize(self.sha1Statement.value)
        sqlite3_finalize(self.searchStatement.value)
        sqlite3_close(self.database.value)
    }

    func get(sha1: String, system: GameSystem) async throws(OpenVGDBError) -> OpenVGDBItem? {
        let statementInt = UInt(bitPattern: sha1Statement.value)
        let statement = OpaquePointer(bitPattern: statementInt)

        guard
            let sha1String = sha1.uppercased().cString(using: .ascii),
            let systemString = system.openVGDBString?.cString(using: .ascii)
        else {
            throw .failedToGetCString
        }

        guard
            sqlite3_bind_text(statement, 1, sha1String, -1, Self.sqliteTransient) == SQLITE_OK,
            sqlite3_bind_text(statement, 2, systemString, -1, Self.sqliteTransient) == SQLITE_OK
        else {
            throw .failedToSetupQuery
        }

        let entry = self.getRow(statement: statement)
        sqlite3_reset(statement)
        return entry
    }

    func search(query: String, system: GameSystem) async throws(OpenVGDBError) -> [OpenVGDBItem] {
        let queryString = query + "*"

        let statementInt = UInt(bitPattern: searchStatement.value)
        let statement = OpaquePointer(bitPattern: statementInt)

        guard
            let queryString = queryString.cString(using: .utf8),
            let systemString = system.openVGDBString?.cString(using: .ascii)
        else {
            throw .failedToGetCString
        }

        guard
            sqlite3_bind_text(statement, 1, queryString, -1, Self.sqliteTransient) == SQLITE_OK,
            sqlite3_bind_text(statement, 2, systemString, -1, Self.sqliteTransient) == SQLITE_OK
        else {
            throw .failedToSetupQuery
        }

        return self.getAllRows(statement: statement)
    }

    private func getRow(statement: OpaquePointer!) -> OpenVGDBItem? {
        guard
            sqlite3_step(statement) == SQLITE_ROW,
            let nameCStr = sqlite3_column_text(statement, 0),
            let systemCStr = sqlite3_column_text(statement, 1),
            let regionCStr = sqlite3_column_text(statement, 2)
        else { return nil }

        let coverUrl: URL? = if let cString = sqlite3_column_text(statement, 3) {
            URL(string: String(cString: cString))
        } else {
            nil
        }

        let entry = OpenVGDBItem(
            name: String(cString: nameCStr),
            system: GameSystem(openVGDBString: String(cString: systemCStr)),
            region: String(cString: regionCStr),
            cover: coverUrl
        )

        return entry
    }

    private func getAllRows(statement: OpaquePointer!) -> [OpenVGDBItem] {
        var output: [OpenVGDBItem] = []
        while let entry = getRow(statement: statement) {
            output.append(entry)
        }
        sqlite3_reset(statement)
        return output
    }
}

