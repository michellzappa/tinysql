import Foundation
import PostgresNIO
import NIOCore
import NIOPosix
import Logging

/// Actor wrapping PostgresNIO for safe concurrent access.
actor DatabaseService {
    private var connection: PostgresConnection?
    private let eventLoopGroup: EventLoopGroup
    private var logger: Logger

    init(eventLoopGroup: EventLoopGroup) {
        self.eventLoopGroup = eventLoopGroup
        self.logger = Logger(label: "com.tinysql.db")
        self.logger.logLevel = .warning
    }

    var isConnected: Bool {
        connection != nil
    }

    func connect(host: String, port: Int, database: String, username: String, password: String) async throws {
        let config = PostgresConnection.Configuration(
            host: host,
            port: port,
            username: username,
            password: password,
            database: database,
            tls: .disable
        )
        let conn = try await PostgresConnection.connect(
            on: eventLoopGroup.any(),
            configuration: config,
            id: 1,
            logger: logger
        )
        self.connection = conn
    }

    func disconnect() async {
        if let conn = connection {
            try? await conn.close()
            connection = nil
        }
    }

    func fetchTables() async throws -> [String] {
        guard let conn = connection else { throw DatabaseError.notConnected }

        let rows = try await conn.query(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name",
            logger: logger
        )

        var tables: [String] = []
        for try await row in rows {
            let (name,) = try row.decode(String.self)
            tables.append(name)
        }
        return tables
    }

    func fetchRows(table: String, limit: Int, offset: Int) async throws -> (columns: [String], rows: [[String]]) {
        guard let conn = connection else { throw DatabaseError.notConnected }

        let query = PostgresQuery(
            unsafeSQL: "SELECT * FROM \"\(table)\" LIMIT \(limit) OFFSET \(offset)"
        )
        let stream = try await conn.query(query, logger: logger)

        var columnNames: [String] = []
        var resultRows: [[String]] = []

        for try await row in stream {
            if columnNames.isEmpty {
                columnNames = row.map { $0.columnName }
            }
            var rowValues: [String] = []
            for cell in row {
                if var buffer = cell.bytes {
                    let str = buffer.readString(length: buffer.readableBytes) ?? "NULL"
                    rowValues.append(str)
                } else {
                    rowValues.append("NULL")
                }
            }
            resultRows.append(rowValues)
        }

        return (columns: columnNames, rows: resultRows)
    }

    func fetchCount(table: String) async throws -> Int {
        guard let conn = connection else { throw DatabaseError.notConnected }

        let query = PostgresQuery(
            unsafeSQL: "SELECT COUNT(*) FROM \"\(table)\""
        )
        let rows = try await conn.query(query, logger: logger)

        for try await row in rows {
            let (count,) = try row.decode(Int.self)
            return count
        }
        return 0
    }
}

enum DatabaseError: LocalizedError {
    case notConnected

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to a database."
        }
    }
}
