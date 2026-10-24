import XCTest

/// Isolated German localization smoke; no real notifications or automation changes.
final class GermanLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testGermanTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Später", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.tabBars.buttons["Verlauf"].firstMatch
        let apps = app.tabBars.buttons["Apps"].firstMatch
        let settings = app.tabBars.buttons["Einstellungen"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Verlauf"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["Apps & Einrichtung"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Einstellungen"].firstMatch.waitForExistence(timeout: 8))
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "pushkin-de-settings"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
