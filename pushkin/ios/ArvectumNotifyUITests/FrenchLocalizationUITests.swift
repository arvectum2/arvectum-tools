import XCTest

/// Native French UI smoke using real bundled strings and no user notifications.
final class FrenchLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testFrenchTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR",
            "--store-tab", "0"
        ]
        app.launch()

        let history = app.tabBars.buttons["Historique"].firstMatch
        let apps = app.tabBars.buttons["Apps"].firstMatch
        let settings = app.tabBars.buttons["Réglages"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Historique"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)

        apps.tap()
        XCTAssertTrue(
            app.navigationBars["Apps et configuration"].firstMatch
                .waitForExistence(timeout: 8)
        )
        settings.tap()
        XCTAssertTrue(
            app.navigationBars["Réglages"].firstMatch.waitForExistence(timeout: 8)
        )

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "pushkin-fr-settings"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
