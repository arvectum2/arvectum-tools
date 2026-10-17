import XCTest

/// Prevent the prior English-only sync diagnostics regression in Russian UI.
final class SyncDiagnosticsLocalizationUITests: XCTestCase {
    func testRussianDiagnosticsAndSettingsMenu() {
        checkDiagnostics(
            language: "ru", locale: "ru_RU",
            libraryButton: "Мои записи", settings: "Настройки и диагностика",
            menuItem: "Диагностика синхронизации",
            title: "Диагностика синхронизации",
            recordings: "Записей", pending: "В очереди на часах",
            noQueueReport: "Отчёт об очереди с часов ещё не получен."
        )
    }

    func testEnglishDiagnosticsAndSettingsMenu() {
        checkDiagnostics(
            language: "en", locale: "en_US",
            libraryButton: "My recordings", settings: "App settings and diagnostics",
            menuItem: "Sync diagnostics", title: "Sync diagnostics",
            recordings: "Recordings", pending: "Pending on Watch",
            noQueueReport: "No Watch queue report received yet."
        )
    }

    private func checkDiagnostics(
        language: String, locale: String, libraryButton: String,
        settings: String, menuItem: String, title: String,
        recordings: String, pending: String, noQueueReport: String
    ) {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", libraryButton)
        ).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 15))
        library.tap()
        let options = app.buttons[settings]
        XCTAssertTrue(options.waitForExistence(timeout: 10))
        options.tap()
        let diagnostics = app.buttons[menuItem]
        XCTAssertTrue(diagnostics.waitForExistence(timeout: 7))
        diagnostics.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[recordings].exists)
        XCTAssertTrue(app.staticTexts[pending].exists
                      || app.staticTexts[noQueueReport].exists)
    }
}
