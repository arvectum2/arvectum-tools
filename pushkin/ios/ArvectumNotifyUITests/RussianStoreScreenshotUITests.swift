import XCTest

/// Synthetic data only; launched on a disposable simulator, not a user device.
final class RussianStoreScreenshotUITests: XCTestCase {
    @MainActor
    func testRussianMarketingSources() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "--store-tab", "1"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Источники"].firstMatch.waitForExistence(timeout: 12))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-RU-store-sources"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testRussianMarketingSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "--store-tab", "2"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Настройки"].firstMatch.waitForExistence(timeout: 12))
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "pushkin-RU-store-settings"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testRussianMarketingHistoryContainsNoEnglishFixture() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-screenshot-fixture", "--store-tab", "0"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Статус доставки"].firstMatch.waitForExistence(timeout: 12))
        XCTAssertFalse(app.staticTexts["Delivery update"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["История"].firstMatch.exists)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "pushkin-RU-store-history-real-ui"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
