import Foundation
import NIOPosix

@Observable
final class AppState {
    // Connection parameters
    var host: String = "localhost"
    var port: Int = 5432
    var database: String = ""
    var username: String = ""
    var password: String = ""

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
    private let db: DatabaseService

    init() {
        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.eventLoopGroup = elg
        self.db = DatabaseService(eventLoopGroup: elg)
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
            try await db.connect(
                host: host,
                port: port,
                database: database,
                username: username,
                password: password
            )
            isConnected = true
            await fetchTables()
            saveLastConnection()
        } catch {
            self.error = error.localizedDescription
        }

        isConnecting = false
    }

    func disconnect() async {
        await db.disconnect()
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
        do {
            tables = try await db.fetchTables()
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
        guard let table = selectedTable else { return }
        isLoading = true
        error = nil

        let start = CFAbsoluteTimeGetCurrent()
        do {
            let result = try await db.fetchRows(table: table, limit: limit, offset: offset)
            columns = result.columns
            rows = result.rows
            queryTime = CFAbsoluteTimeGetCurrent() - start
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func fetchRowCount() async {
        guard let table = selectedTable else { return }
        do {
            totalRowCount = try await db.fetchCount(table: table)
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
        UserDefaults.standard.set(host, forKey: "lastHost")
        UserDefaults.standard.set(port, forKey: "lastPort")
        UserDefaults.standard.set(database, forKey: "lastDatabase")
        UserDefaults.standard.set(username, forKey: "lastUsername")
    }

    func restoreLastConnection() {
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
    }
}
