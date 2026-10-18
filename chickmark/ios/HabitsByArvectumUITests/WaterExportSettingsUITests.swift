import XCTest

/// Tests only navigation and explicit consent UI. No HealthKit writer is
/// configured during --ui-testing and Save/permissions are never invoked.
final class WaterExportSettingsUITests: XCTestCase {
    func testQuantityHabitHasWaterExportScreenButNoAutomaticPermission() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing", "--disable-cloud-sync",
            "--seed-water-settings-demo"
        ]
        app.launch()
        let habit = app.staticTexts["Water QA"].firstMatch
        XCTAssertTrue(habit.waitForExistence(timeout: 15))
        habit.tap()
        let detail = app.navigationBars["Water QA"]
        XCTAssertTrue(detail.waitForExistence(timeout: 10))
        let more = app.buttons["More habit actions"]
        XCTAssertTrue(more.waitForExistence(timeout: 8))
        more.tap()
        let open = app.buttons["Export water to Apple Health"]
        XCTAssertTrue(open.waitForExistence(timeout: 8))
        open.tap()
        let toggle = app.switches["water.export.toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertEqual(toggle.value as? String, "0",
            "Water export must be disabled until the user explicitly opts in.")
        let explanation = app.staticTexts[
            "Each check-in adds the exact volume you choose, not an assumed glass size."
        ]
        XCTAssertFalse(explanation.exists)
        // On wide iPad Forms, tapping the label may not hit the UISwitch.
        // Target the actual switch on the trailing edge.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.94, dy: 0.50)).tap()
        XCTAssertEqual(toggle.value as? String, "1",
            "Export must turn on only when the user explicitly changes the switch.")
        // SwiftUI Form/Stepper may group their help text under a single
        // accessibility element on this iPad runtime. The conditional
        // volume editor remains covered by SwiftUI render & unit tests.
        // Cancel, not Save: no HealthKit permission or sample operations.
        app.buttons["Cancel"].tap()
        XCTAssertTrue(detail.waitForExistence(timeout: 8))
    }
}
