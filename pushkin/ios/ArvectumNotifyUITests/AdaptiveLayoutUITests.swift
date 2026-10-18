import XCTest

/// Simulator fixture only; real notification history is never touched.
final class AdaptiveLayoutUITests: XCTestCase {
    func testHistoryAndSearchSurviveOrientationChanges() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 14))
        let search = app.textFields["Search notifications"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Delivery")
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    func testSetupRemainsAccessibleAfterRotation() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        let apps = app.descendants(matching: .any)["Apps"].firstMatch
        XCTAssertTrue(apps.waitForExistence(timeout: 8))
        apps.tap()
        XCTAssertTrue(app.staticTexts["Apps & Setup"].firstMatch.waitForExistence(timeout: 8)
                      || app.navigationBars["Apps & Setup"].firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["Apps"].exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["History"].exists)
    }
}
