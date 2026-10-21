import XCTest

/// Only UI copy and navigation; no Shortcuts automation or user data changes.
final class SpanishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSpanishTabsAndNavigation() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "--store-tab", "0"
        ]
        app.launch()

        let history = app.tabBars.buttons["Historial"].firstMatch
        let apps = app.tabBars.buttons["Aplicaciones"].firstMatch
        let settings = app.tabBars.buttons["Ajustes"].firstMatch
        XCTAssertTrue(history.waitForExistence(timeout: 12))
        XCTAssertTrue(apps.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(app.navigationBars["Historial"].firstMatch.exists)
        // The already-selected tab is a visible accessibility item but
        // iOS can report it as not hittable while its content is active.
        // Validate the navigation actions that users actually tap.
        XCTAssertTrue(apps.isHittable)
        XCTAssertTrue(settings.isHittable)

        apps.tap()
        // Tab label is "Aplicaciones"; its destination screen is
        // "Apps & Setup" -> "Aplicaciones y configuración".
        XCTAssertTrue(app.navigationBars["Aplicaciones y configuración"]
            .firstMatch.waitForExistence(timeout: 8))
        settings.tap()
        XCTAssertTrue(app.navigationBars["Ajustes"].firstMatch.waitForExistence(timeout: 8))

        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "pushkin-es-settings"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
