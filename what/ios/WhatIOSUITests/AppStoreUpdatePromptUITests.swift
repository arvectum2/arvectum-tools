import XCTest

/// Hermetic UI QA: only synthetic DEBUG App Store version, no upload/download
/// and no interactions with production user accounts or personal content.
final class AppStoreUpdatePromptUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.what")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--ui-testing", "--qa-appstore-update"
        ]
        app.launch()
        let consent = app.buttons["ad-consent-decline"]
        if consent.waitForExistence(timeout: 3) { consent.tap() }
        return app
    }

    private func checkPrompt(_ app: XCUIApplication) {
        let update = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Обновить", "Update")
        ).firstMatch
        XCTAssertTrue(update.waitForExistence(timeout: 18), "New App Store version should prompt")
        XCTAssertTrue(update.isHittable)
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Позже", "Later")
        ).firstMatch
        XCTAssertTrue(later.exists)
    }

    func testLaterDismissesUntilNextLaunch() {
        let app = launch()
        checkPrompt(app)
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Позже", "Later")
        ).firstMatch
        later.tap()
        XCTAssertFalse(app.buttons["Обновить"].waitForExistence(timeout: 2))
        app.terminate()
        app.launch()
        checkPrompt(app)
    }
}
