import XCTest

/// Isolated BrazilianPortuguese localization smoke; no real notifications or automation changes.
final class BrazilianPortugueseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testBrazilianPortugueseTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(pt-BR)", "-AppleLocale", "pt_BR", "--store-tab", "0"]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Mais tarde", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        let history = app.tabBars.buttons["Histórico"].firstMatch
        let apps = app.tabBars.buttons["Apps"].firstMatch
        let settings = app.tabBars.buttons["Ajustes"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Histórico"].firstMatch.exists)
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(apps.isHittable)
        apps.tap()
        XCTAssertTrue(app.navigationBars["Apps e configuração"].firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].firstMatch.waitForExistence(timeout: 8))
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "pushkin-de-settings"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
