import XCTest

/// Simulator-only acceptance: uses an in-memory model, never iCloud/Health history.
final class AdaptiveLayoutUITests: XCTestCase {
    func testCreateHabitAndKeepItAcrossOrientationChanges() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let create = app.buttons["Create habit"]
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        create.tap()
        let name = app.textFields["Habit name"]
        XCTAssertTrue(name.waitForExistence(timeout: 8))
        name.tap()
        name.typeText("Responsive QA")
        app.navigationBars["New habit"].buttons["Done"].tap()
        let habit = app.staticTexts["Responsive QA"].firstMatch
        XCTAssertTrue(habit.waitForExistence(timeout: 8))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(habit.waitForExistence(timeout: 8))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(habit.waitForExistence(timeout: 8))
    }
}
