import XCTest

/// Real localized app screens with synthetic notification content in DEBUG.
/// No customer notification history is accessed or modified.
final class ASOAllLocalesCaptureUITests: XCTestCase {
    @MainActor
    func testAllBundledLocalesHistorySourcesSettings() {
        let locales = [
            ("ru", "ru_RU"), ("en", "en_US"), ("es", "es_ES"),
            ("fr", "fr_FR"), ("de", "de_DE"), ("it", "it_IT"),
            ("ja", "ja_JP"), ("ko", "ko_KR"), ("pt-BR", "pt_BR"),
            ("pt-PT", "pt_PT"), ("zh-Hans", "zh_Hans_CN"),
            ("zh-Hant", "zh_Hant_TW")
        ]
        let names = ["history", "sources", "settings"]
        for (language, region) in locales {
            let app = XCUIApplication()
            app.launchArguments = [
                "-AppleLanguages", "(\(language))", "-AppleLocale", region,
                "--store-screenshot-fixture", "--store-tab", "0"
            ]
            app.launch()
            guard app.tabBars.buttons.element(boundBy: 0).waitForExistence(timeout: 12) else {
                XCTFail("Missing tabs for \(language)")
                app.terminate()
                continue
            }
            // A brand source is independent of translated sample-message text.
            XCTAssertTrue(app.staticTexts["Telegram"].firstMatch.waitForExistence(timeout: 9),
                          "Synthetic source not visible for \(language)")
            for (tabIndex, title) in names.enumerated() {
                let tab = app.tabBars.buttons.element(boundBy: tabIndex)
                if tabIndex > 0 { tab.tap() }
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
                if title == "settings" { app.swipeUp() }
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "aso-pushkin--\(language)--\(title)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            app.tabBars.buttons.element(boundBy: 0).tap()
            let search = app.textFields.firstMatch
            if search.waitForExistence(timeout: 8) {
                search.tap()
                search.typeText("Telegram")
                XCTAssertTrue(app.staticTexts["Telegram"].firstMatch.waitForExistence(timeout: 8))
                let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                attachment.name = "aso-pushkin--\(language)--search"
                attachment.lifetime = .keepAlways
                add(attachment)
            } else {
                XCTFail("Search field absent in \(language)")
            }
            app.terminate()
        }
    }
}
