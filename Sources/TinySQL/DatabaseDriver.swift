import Foundation

/// Common interface for database backends (PostgreSQL, SQLite, etc.).
protocol DatabaseDriver: Actor {
    var isConnected: Bool { get }
    func disconnect() async
    func fetchTables() async throws -> [String]
    func fetchRows(table: String, limit: Int, offset: Int) async throws -> (columns: [String], rows: [[String]])
    func fetchCount(table: String) async throws -> Int
}

enum DatabaseError: LocalizedError {
    case notConnected
    case sqliteError(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to a database."
        case .sqliteError(let message):
            return message
        }
    }
}
