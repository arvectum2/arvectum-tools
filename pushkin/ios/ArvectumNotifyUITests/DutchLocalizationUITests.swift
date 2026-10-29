import XCTest

/// Dutch iPhone simulator source check: no personal notifications or Shortcuts edits.
final class DutchLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testDutchTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(nl)", "-AppleLocale", "nl_NL", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.tabBars.buttons["Geschiedenis"].firstMatch
        let apps = app.tabBars.buttons["Apps"].firstMatch
        let settings = app.tabBars.buttons["Instellingen"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Geschiedenis"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["Apps en configuratie"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Instellingen"].firstMatch.waitForExistence(timeout: 8))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-nl-settings"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
