import XCTest

/// Isolated simulator only: does not touch a person's habits or Health.
final class GentleRestartUITests: XCTestCase {
    func testOptInAndThresholdInManagePreferences() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--disable-cloud-sync"
        ]
        app.launch()
        let manage = app.buttons["Manage habits"]
        XCTAssertTrue(manage.waitForExistence(timeout: 10))
        manage.tap()

        let preferences = app.descendants(matching: .any)[
            "manage.gentle-restart"
        ]
        XCTAssertTrue(preferences.waitForExistence(timeout: 8))
        preferences.tap()
        let toggle = app.switches["restart-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 8))
        let before = toggle.value as? String
        toggle.tap()
        XCTAssertNotEqual(toggle.value as? String, before)
        XCTAssertTrue(app.descendants(matching: .any)[
            "restart-threshold"
        ].exists)
        toggle.tap()
        XCTAssertEqual(toggle.value as? String, before)
        XCTAssertTrue(app.navigationBars["Gentle Restart"].exists)
    }
}
