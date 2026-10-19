import XCTest

final class NotificationDeletionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchFixture() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        // This existing DEBUG-only fixture is used solely by these simulator
        // UI tests. Never run it against a user device or real history.
        app.launchArguments += ["--store-screenshot-fixture"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 15))
        return app
    }

    func testDeleteFromDetailReturnsToHistoryAndPreservesAnotherRow() {
        let app = launchFixture()

        app.staticTexts["Delivery update"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Your order will arrive between 18:00 and 19:00."].firstMatch
            .waitForExistence(timeout: 8))
        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.exists)
        delete.tap()

        let confirmation = app.buttons["Delete"].firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 7))
        confirmation.tap()

        XCTAssertTrue(app.staticTexts["Your booking is confirmed"].firstMatch
            .waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Delivery update"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["History"].firstMatch.exists)
    }

    func testSwipeDeleteKeepsOtherRowsAndAppRunning() {
        let app = launchFixture()
        let row = app.staticTexts["Design team"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        row.swipeLeft()

        let delete = app.buttons["Delete"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 8))
        delete.tap()
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts["Design team"].firstMatch.exists)
    }

    func testDeleteAllFromSettingsKeepsAppOperational() {
        let app = launchFixture()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["On this iPhone"].firstMatch.waitForExistence(timeout: 8))
        app.buttons["Delete all history"].firstMatch.tap()

        let delete = app.buttons["Delete All"].firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 8))
        delete.tap()

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History is empty"].firstMatch
            .waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}
