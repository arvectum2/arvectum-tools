import XCTest

/// Isolated simulator only: does not touch a person's habits or Health.
final class GentleRestartUITests: XCTestCase {
    func testGentleRestartSettingsSystemAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let manage = app.buttons["Управление привычками"]
        XCTAssertTrue(manage.waitForExistence(timeout: 12))
        manage.tap()
        let settings = app.descendants(matching: .any)[
            "manage.gentle-restart"
        ]
        for _ in 0..<12 where !settings.isHittable { app.swipeUp() }
        XCTAssertTrue(settings.isHittable)
        settings.tap()
        let toggle = app.switches["restart-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["После перерыва"].exists,
                      "The chosen period is shown as information when off")
        XCTAssertFalse(app.buttons["restart-threshold"].exists,
                       "Disabled period must not appear as an actionable Picker")
        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("CHICKMARK_RESTART_AX issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil") " +
                  "detail=\(issue.detailedDescription)")
            return false
        }
        // Do not toggle or modify personal habits or preferences.
    }

    func testEnabledPeriodSystemAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let manage = app.buttons["Управление привычками"]
        XCTAssertTrue(manage.waitForExistence(timeout: 12))
        manage.tap()
        let settings = app.descendants(matching: .any)["manage.gentle-restart"]
        for _ in 0..<12 where !settings.isHittable { app.swipeUp() }
        XCTAssertTrue(settings.isHittable)
        settings.tap()
        let toggle = app.switches["restart-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let wasEnabled = toggle.value as? String == "1"
        if !wasEnabled {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        }
        defer {
            if !wasEnabled && toggle.exists {
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
            }
        }
        let threshold = app.descendants(matching: .any)["restart-threshold"]
        XCTAssertTrue(threshold.waitForExistence(timeout: 10),
                      "Period picker should be interactive while enabled")
        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("CHICKMARK_RESTART_ENABLED_AX issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil") " +
                  "detail=\(issue.detailedDescription)")
            return false
        }
    }

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
        // The settings row is below the habits in a lazy scrolling List.
        // At normal Dynamic Type it may not exist until scrolled into view.
        for _ in 0..<12 where !preferences.isHittable { app.swipeUp() }
        XCTAssertTrue(preferences.isHittable)
        preferences.tap()
        let toggle = app.switches["restart-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 8))
        let before = toggle.value as? String
        // On iOS 27 the accessibility switch can expose a wide Form row;
        // tap the actual trailing control rather than the row centre.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertNotEqual(toggle.value as? String, before)
        XCTAssertTrue(app.descendants(matching: .any)[
            "restart-threshold"
        ].exists)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, before)
        XCTAssertTrue(
            app.navigationBars["Gentle Restart"].exists ||
            app.navigationBars["Restart"].exists,
            "Navigation title adapts to Accessibility Dynamic Type"
        )
    }
}
