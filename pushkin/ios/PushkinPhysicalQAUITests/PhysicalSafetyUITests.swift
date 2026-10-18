import XCTest

/// Physical iPhone only: all mutations restricted to a distinct QA app and
/// five synthetic DEBUG fixtures. Never targets ru.arvectum.tools.notify.
final class PhysicalSafetyUITests: XCTestCase {
    private let qaBundle = "ru.arvectum.tools.notify.physicalqa"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func fixtureApp() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: qaBundle)
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 18))
        return app
    }

    func testSearchFixtureWithoutRequestingPersonalNotifications() {
        let app = fixtureApp()
        let search = app.textFields["Search notifications"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Delivery")
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 7))
        XCTAssertFalse(app.staticTexts["Your booking is confirmed"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }

    func testDeleteOneSyntheticRecordKeepsAnother() {
        let app = fixtureApp()
        app.staticTexts["Delivery update"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Your order will arrive between 18:00 and 19:00."].firstMatch
            .waitForExistence(timeout: 10))
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Your booking is confirmed"].firstMatch
            .waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Delivery update"].firstMatch.exists)
    }

    func testClearAllSyntheticHistoryLeavesQAAppOperational() {
        let app = fixtureApp()
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["On this iPhone"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Delete all history"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Delete All"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Delete All"].firstMatch.tap()
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Never lose a notification"].firstMatch
            .waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }
}
