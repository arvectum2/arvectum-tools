import XCTest

final class ChickMarkWeeklySummaryUITests: XCTestCase {
    func testLocalOptInShowsCompletedWeekWithoutCreatingRecords() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()

        let manage = app.buttons["Manage habits"]
        XCTAssertTrue(manage.waitForExistence(timeout: 10))
        manage.tap()
        let weekly = app.descendants(matching: .any)[
            "manage.weekly-summary"
        ]
        XCTAssertTrue(weekly.waitForExistence(timeout: 8))
        weekly.tap()

        XCTAssertTrue(app.navigationBars["Weekly summary"].waitForExistence(timeout: 8))
        let toggle = app.switches["weekly-opt-in"]
        XCTAssertTrue(toggle.exists)
        if toggle.value as? String != "1" {
            toggle.coordinate(
                withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)
            ).tap()
        }
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertTrue(app.staticTexts["Last completed calendar week"].exists)
        XCTAssertTrue(app.staticTexts["Activity"].exists)

        toggle.coordinate(
            withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)
        ).tap()
        XCTAssertEqual(toggle.value as? String, "0")
        XCTAssertFalse(app.staticTexts["Last completed calendar week"].exists)
    }
}
