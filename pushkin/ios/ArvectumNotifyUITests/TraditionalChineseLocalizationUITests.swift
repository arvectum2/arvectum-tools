import XCTest

/// Isolated TraditionalChinese localization smoke; no real notifications or automation changes.
final class TraditionalChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTraditionalChineseTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_Hant_TW", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "稍後", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.tabBars.buttons["歷史記錄"].firstMatch
        let apps = app.tabBars.buttons["應用"].firstMatch
        let settings = app.tabBars.buttons["設定"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["歷史記錄"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["應用與設定"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["設定"].firstMatch.waitForExistence(timeout: 8))
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "pushkin-it-settings"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
