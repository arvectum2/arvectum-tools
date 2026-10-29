import XCTest

/// Indonesian iPhone simulator source check: no personal notifications or Shortcuts edits.
final class IndonesianLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testIndonesianTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(id)", "-AppleLocale", "id_ID", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.buttons["Riwayat"].firstMatch
        let apps = app.buttons["Aplikasi"].firstMatch
        let settings = app.buttons["Pengaturan"].firstMatch
        if !history.waitForExistence(timeout: 12) {
            XCTFail("Indonesian history tab missing. Accessibility tree: \(app.debugDescription)")
            return
        }
        XCTAssertTrue(app.navigationBars["Riwayat"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["Aplikasi & Pengaturan"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Pengaturan"].firstMatch.waitForExistence(timeout: 8))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-id-settings"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
