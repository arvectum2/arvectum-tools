import XCTest

/// Polish iPhone simulator smoke, synthetic empty inbox; does not alter Shortcuts.
final class PolishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPolishTabsSetupAndSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let history = app.buttons["Historia"].firstMatch
        let apps = app.buttons["Aplikacje"].firstMatch
        let settings = app.buttons["Ustawienia"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(app.navigationBars["Historia"].firstMatch.exists)
        apps.tap()
        XCTAssertTrue(app.navigationBars["Aplikacje i konfiguracja"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Ustawienia"].firstMatch.waitForExistence(timeout: 8))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-pl-settings"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
