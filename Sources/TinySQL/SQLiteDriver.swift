import Foundation
import SQLite3

/// SQLite database driver using the system SQLite3 C library.
actor SQLiteDriver: DatabaseDriver {
    private var db: OpaquePointer?

    var isConnected: Bool {
        db != nil
    }

    func connect(path: String) throws {
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX
        let rc = sqlite3_open_v2(path, &handle, flags, nil)
        guard rc == SQLITE_OK, let handle else {
            let msg = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            sqlite3_close(handle)
            throw DatabaseError.sqliteError("Failed to open database: \(msg)")
        }
        self.db = handle
    }

    func disconnect() async {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
    }

    func fetchTables() async throws -> [String] {
        guard let db else { throw DatabaseError.notConnected }

        let sql = "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.sqliteError(errorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        var tables: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cStr = sqlite3_column_text(stmt, 0) {
                tables.append(String(cString: cStr))
            }
        }
        return tables
    }

    func fetchRows(table: String, limit: Int, offset: Int) async throws -> (columns: [String], rows: [[String]]) {
        guard let db else { throw DatabaseError.notConnected }

        let sql = "SELECT * FROM \"\(table)\" LIMIT \(limit) OFFSET \(offset)"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.sqliteError(errorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        let colCount = Int(sqlite3_column_count(stmt))
        let columnNames = (0..<colCount).map { i in
            String(cString: sqlite3_column_name(stmt, Int32(i)))
        }

        var resultRows: [[String]] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String] = []
            for i in 0..<colCount {
                if sqlite3_column_type(stmt, Int32(i)) == SQLITE_NULL {
                    row.append("NULL")
                } else if let text = sqlite3_column_text(stmt, Int32(i)) {
                    row.append(String(cString: text))
                } else {
                    row.append("NULL")
                }
            }
            resultRows.append(row)
        }

        return (columns: columnNames, rows: resultRows)
    }

    func fetchCount(table: String) async throws -> Int {
        guard let db else { throw DatabaseError.notConnected }

        let sql = "SELECT COUNT(*) FROM \"\(table)\""
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DatabaseError.sqliteError(errorMessage)
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int64(stmt, 0))
        }
        return 0
    }

    private var errorMessage: String {
        if let db {
            return String(cString: sqlite3_errmsg(db))
        }
        return "Database not connected"
    }
}
