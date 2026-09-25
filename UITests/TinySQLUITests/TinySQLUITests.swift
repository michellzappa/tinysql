import Foundation
import XCTest

final class TinySQLUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesWithFixtureAndShowsLoadedTable() {
        let fixturePath = fixturePath(named: "sample.db")
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing", "--disable-ai", "--disable-spotlight", "--disable-file-watchers"]
        app.launchEnvironment["TINY_FIXTURE_PATH"] = fixturePath

        app.launch()

        let probe = app.staticTexts["ui-smoke-status"]
        XCTAssertTrue(probe.waitForExistence(timeout: 10))
        XCTAssertTrue(probe.label.contains("sample.db"))
        XCTAssertTrue(probe.label.contains("table:people"))
        XCTAssertTrue(probe.label.contains("rows:2"))
    }

    private func fixturePath(named name: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name)")
            .path
    }
}
