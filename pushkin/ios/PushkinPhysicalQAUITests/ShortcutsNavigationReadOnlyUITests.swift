import XCTest

/// Read-only navigation coverage for iOS 27 Shortcuts. Does not interact
/// with, print names of, or change any existing user automations.
final class ShortcutsNavigationReadOnlyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testNavigationToAutomationsWithoutMutation() {
        let app = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        app.launch()
        // iOS can restore an editor or nested "All Shortcuts" when launched.
        // The first BackButton navigates toward Library; never Save/Replace.
        let back = app.buttons["BackButton"].firstMatch
        if back.waitForExistence(timeout: 3), back.isHittable {
            back.tap()
        }
        let automation = app.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@", "Automation", "Автоматизация"
        )).firstMatch
        XCTAssertTrue(automation.waitForExistence(timeout: 10),
                      "Automation tab must be accessible without edits.")
        automation.tap()
        XCTAssertTrue(app.navigationBars["Автоматизация"].waitForExistence(timeout: 8)
                     || app.navigationBars["Automation"].exists)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        // No tapping an item, importing a shortcut, or toggling an automation.
    }
}
