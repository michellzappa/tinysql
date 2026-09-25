import XCTest
@testable import TinySQL

actor FakeDriver: DatabaseDriver {
    let isConnected: Bool = true

    func disconnect() async {}

    func fetchTables() async throws -> [String] {
        ["people"]
    }

    func fetchRows(table: String, limit: Int, offset: Int) async throws -> (columns: [String], rows: [[String]]) {
        (["id", "name"], [["1", "Ada"], ["2", "Linus"]])
    }

    func fetchCount(table: String) async throws -> Int {
        2
    }
}

final class AppStateTests: XCTestCase {
    private let defaultsKeys = [
        "lastConnectionType",
        "lastHost",
        "lastPort",
        "lastDatabase",
        "lastUsername",
        "lastSQLitePath",
    ]

    override func tearDown() {
        defaultsKeys.forEach(UserDefaults.standard.removeObject(forKey:))
        super.tearDown()
    }

    func testPageDescriptionAndPaginationFlags() {
        let state = AppState(testDriver: FakeDriver())
        state.limit = 100
        state.offset = 100
        state.totalRowCount = 250

        XCTAssertEqual(state.pageDescription, "101–200 of 250")
        XCTAssertTrue(state.canGoNext)
        XCTAssertTrue(state.canGoPrevious)
    }

    func testFetchTablesSelectTableAndAIDocument() async {
        let state = AppState(testDriver: FakeDriver())
        state.connectionType = .sqlite
        state.sqliteFilePath = "/tmp/sample.db"
        state.isConnected = true

        await state.fetchTables()
        await state.selectTable("people")

        XCTAssertEqual(state.tables, ["people"])
        XCTAssertEqual(state.columns, ["id", "name"])
        XCTAssertEqual(state.rows.count, 2)
        XCTAssertEqual(state.totalRowCount, 2)
        XCTAssertTrue(state.aiDocument.contains("Selected table: people"))
        XCTAssertTrue(state.aiDocument.contains("Ada"))
    }

    func testRestoreLastConnectionAndOpenSQLiteFixture() async {
        let fixture = fixtureURL(named: "sample.db")
        let state = AppState()
        state.connectionType = .sqlite
        state.sqliteFilePath = fixture.path
        state.saveLastConnection()

        let restored = AppState()
        restored.restoreLastConnection()

        XCTAssertEqual(restored.connectionType, .sqlite)
        XCTAssertEqual(restored.sqliteFilePath, fixture.path)

        await restored.openSQLiteFile(fixture)

        XCTAssertTrue(restored.isConnected)
        XCTAssertEqual(restored.tables, ["people"])
        XCTAssertEqual(restored.selectedTable, "people")
        XCTAssertEqual(restored.rows.count, 2)
    }

    private func fixtureURL(named name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("UITests/Fixtures/\(name)")
    }
}
