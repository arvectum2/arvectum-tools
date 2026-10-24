import XCTest

/// Isolated SimplifiedChinese localization smoke; no real notifications or automation changes.
final class SimplifiedChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSimplifiedChineseTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans_CN", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "稍后", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.tabBars.buttons["历史记录"].firstMatch
        let apps = app.tabBars.buttons["应用"].firstMatch
        let settings = app.tabBars.buttons["设置"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["历史记录"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["应用与设置"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["设置"].firstMatch.waitForExistence(timeout: 8))
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "pushkin-it-settings"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
