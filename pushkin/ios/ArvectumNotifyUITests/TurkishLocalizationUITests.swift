import XCTest

/// Turkish iPhone simulator source check: no personal notifications or Shortcuts edits.
final class TurkishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTurkishTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.buttons["Geçmiş"].firstMatch
        let apps = app.buttons["Aplikasi"].firstMatch
        let settings = app.buttons["Ayarlar"].firstMatch
        if !history.waitForExistence(timeout: 12) {
            XCTFail("Turkish history tab missing. Accessibility tree: \(app.debugDescription)")
            return
        }
        XCTAssertTrue(app.navigationBars["Geçmiş"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["Uygulamalar ve Kurulum"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Ayarlar"].firstMatch.waitForExistence(timeout: 8))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-id-settings"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
