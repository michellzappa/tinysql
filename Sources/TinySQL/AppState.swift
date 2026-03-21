import Foundation
import NIOPosix

enum ConnectionType: String, CaseIterable {
    case postgres = "PostgreSQL"
    case sqlite = "SQLite"
}

@Observable
final class AppState {
    // Connection type
    var connectionType: ConnectionType = .postgres

    // PostgreSQL connection parameters
    var host: String = "localhost"
    var port: Int = 5432
    var database: String = ""
    var username: String = ""
    var password: String = ""

    // SQLite connection parameters
    var sqliteFilePath: String = ""
    var sqliteBookmark: Data?

    // Connection state
    var isConnected: Bool = false
    var isConnecting: Bool = false
    var isLoading: Bool = false
    var error: String?

    // Schema
    var tables: [String] = []
    var selectedTable: String?

    // Query results
    var columns: [String] = []
    var rows: [[String]] = []
    var totalRowCount: Int = 0
    var queryTime: TimeInterval = 0

    // Pagination
    var limit: Int = 100
    var offset: Int = 0

    // Internal
    private let eventLoopGroup: MultiThreadedEventLoopGroup
    private let postgresDriver: PostgresDriver
    private var sqliteDriver: SQLiteDriver?

    /// The currently active driver.
    private var activeDriver: (any DatabaseDriver)? {
        switch connectionType {
        case .postgres: return postgresDriver
        case .sqlite: return sqliteDriver
        }
    }

    /// Display name for the current connection (used in window title).
    var connectionDisplayName: String {
        switch connectionType {
        case .postgres: return database
        case .sqlite: return (sqliteFilePath as NSString).lastPathComponent
        }
    }

    init() {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.eventLoopGroup = elg
        self.postgresDriver = PostgresDriver(eventLoopGroup: elg)
    }

    deinit {
        try? eventLoopGroup.syncShutdownGracefully()
    }

    // MARK: - Connection

    func connect() async {
        guard !isConnecting else { return }
        isConnecting = true
        error = nil

        do {
            switch connectionType {
            case .postgres:
                try await postgresDriver.connect(
                    host: host,
                    port: port,
                    database: database,
                    username: username,
                    password: password
                )
            case .sqlite:
                let driver = SQLiteDriver()
                try await driver.connect(path: sqliteFilePath)
                self.sqliteDriver = driver
            }
            isConnected = true
            await fetchTables()
            saveLastConnection()
        } catch {
            self.error = error.localizedDescription
        }

        isConnecting = false
    }

    func disconnect() async {
        if let driver = activeDriver {
            await driver.disconnect()
        }
        if connectionType == .sqlite {
            sqliteDriver = nil
        }
        isConnected = false
        tables = []
        selectedTable = nil
        columns = []
        rows = []
        totalRowCount = 0
        error = nil
    }

    // MARK: - Queries

    func fetchTables() async {
        guard let driver = activeDriver else { return }
        do {
            tables = try await driver.fetchTables()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectTable(_ name: String) async {
        selectedTable = name
        offset = 0
        await fetchTableData()
        await fetchRowCount()
    }

    func fetchTableData() async {
        guard let table = selectedTable, let driver = activeDriver else { return }
        isLoading = true
        error = nil

        let start = CFAbsoluteTimeGetCurrent()
        do {
            let result = try await driver.fetchRows(table: table, limit: limit, offset: offset)
            columns = result.columns
            rows = result.rows
            queryTime = CFAbsoluteTimeGetCurrent() - start
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchRowCount() async {
        guard let table = selectedTable, let driver = activeDriver else { return }
        do {
            totalRowCount = try await driver.fetchCount(table: table)
        } catch {
            // Non-critical, don't overwrite other errors
        }
    }

    // MARK: - Pagination

    var canGoNext: Bool { offset + limit < totalRowCount }
    var canGoPrevious: Bool { offset > 0 }

    var pageDescription: String {
        guard totalRowCount > 0 else { return "0 rows" }
        let start = offset + 1
        let end = min(offset + limit, totalRowCount)
        return "\(start)–\(end) of \(totalRowCount)"
    }

    func nextPage() async {
        guard canGoNext else { return }
        offset += limit
        await fetchTableData()
    }

    func previousPage() async {
        guard canGoPrevious else { return }
        offset = max(offset - limit, 0)
        await fetchTableData()
    }

    // MARK: - Persistence

    private func saveLastConnection() {
        UserDefaults.standard.set(connectionType.rawValue, forKey: "lastConnectionType")
        switch connectionType {
        case .postgres:
            UserDefaults.standard.set(host, forKey: "lastHost")
            UserDefaults.standard.set(port, forKey: "lastPort")
            UserDefaults.standard.set(database, forKey: "lastDatabase")
            UserDefaults.standard.set(username, forKey: "lastUsername")
        case .sqlite:
            UserDefaults.standard.set(sqliteFilePath, forKey: "lastSQLitePath")
        }
    }

    func restoreLastConnection() {
        if let typeStr = UserDefaults.standard.string(forKey: "lastConnectionType"),
           let type = ConnectionType(rawValue: typeStr) {
            connectionType = type
        }

        // Restore PostgreSQL settings
        if let h = UserDefaults.standard.string(forKey: "lastHost"), !h.isEmpty {
            host = h
        }
        let p = UserDefaults.standard.integer(forKey: "lastPort")
        if p > 0 { port = p }
        if let d = UserDefaults.standard.string(forKey: "lastDatabase") {
            database = d
        }
        if let u = UserDefaults.standard.string(forKey: "lastUsername") {
            username = u
        }

        // Restore SQLite settings
        if let path = UserDefaults.standard.string(forKey: "lastSQLitePath") {
            sqliteFilePath = path
        }
    }
}
