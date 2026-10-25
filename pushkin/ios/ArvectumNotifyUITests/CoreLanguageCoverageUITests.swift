import XCTest

/// Baseline languages tested in an isolated simulator; no Shortcuts changes.
final class CoreLanguageCoverageUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func checkBaseline(
        language: String,
        locale: String,
        historyTitle: String,
        appsTab: String,
        appsTitle: String,
        settingsTitle: String
    ) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "--store-tab", "0"
        ]
        app.launch()
        let history = app.tabBars.buttons[historyTitle].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars[historyTitle].firstMatch.exists)
        let apps = app.tabBars.buttons[appsTab].firstMatch
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars[appsTitle].firstMatch.waitForExistence(timeout: 8))
        let settings = app.tabBars.buttons[settingsTitle].firstMatch
        XCTAssertTrue(settings.exists)
        settings.tap()
        XCTAssertTrue(app.navigationBars[settingsTitle].firstMatch.waitForExistence(timeout: 8))

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-\(language)-settings"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testRussianBaselineTabs() {
        checkBaseline(language: "ru", locale: "ru_RU",
                      historyTitle: "История",
                      appsTab: "Источники", appsTitle: "Источники",
                      settingsTitle: "Настройки")
    }

    @MainActor
    func testEnglishBaselineTabs() {
        checkBaseline(language: "en", locale: "en_US",
                      historyTitle: "History", appsTab: "Apps",
                      appsTitle: "Apps & Setup", settingsTitle: "Settings")
    }
}
