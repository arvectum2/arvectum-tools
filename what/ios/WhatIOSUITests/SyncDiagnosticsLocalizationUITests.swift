import XCTest

/// Prevent the prior English-only sync diagnostics regression in Russian UI.
final class SyncDiagnosticsLocalizationUITests: XCTestCase {
    func testRussianDiagnosticsAndSettingsMenu() {
        checkDiagnostics(
            language: "ru", locale: "ru_RU",
            libraryButton: "Все заметки", settings: "Настройки и диагностика",
            menuItem: "Диагностика синхронизации",
            title: "Диагностика синхронизации",
            recordings: "Записей", pending: "В очереди на часах",
            noQueueReport: "Отчёт об очереди с часов ещё не получен."
        )
    }

    func testEnglishDiagnosticsAndSettingsMenu() {
        checkDiagnostics(
            language: "en", locale: "en_US",
            libraryButton: "All notes", settings: "App settings and diagnostics",
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
        // A previously saved speech/UI locale has priority over system
        // -AppleLanguages, so this test must first select the requested
        // locale through the actual UI rather than assuming a clean install.
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Все заметки", "All notes")
        ).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 15))
        library.tap()
        selectLocale(language == "ru" ? "Русский" : "English", app: app)
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
        // This view is a modal sheet, not a pushed navigation route.
        // A user must be able to close it without killing the application.
        let close = app.buttons["syncDiagnosticsClose"]
        XCTAssertTrue(close.waitForExistence(timeout: 6))
        close.tap()
        XCTAssertTrue(app.buttons[settings].waitForExistence(timeout: 7))
    }

    func testSpeechLanguageAlsoSwitchesTheLiveInterfaceAndPersists() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Все заметки", "All notes")
        ).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 15))
        library.tap()

        selectLocale("English", app: app)
        XCTAssertTrue(app.buttons["App settings and diagnostics"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["UhWhat?"].exists)

        // This is not only a transient SwiftUI state; the locale must survive
        // a normal app relaunch and still drive UI and Speech together.
        app.terminate()
        app.launch()
        let englishLibrary = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "All notes")
        ).firstMatch
        XCTAssertTrue(englishLibrary.waitForExistence(timeout: 15))
        englishLibrary.tap()
        XCTAssertTrue(app.buttons["App settings and diagnostics"]
                      .waitForExistence(timeout: 10))

        selectLocale("Русский", app: app)
        XCTAssertTrue(app.buttons["Настройки и диагностика"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Ухват"].exists)
    }

    private func selectLocale(_ locale: String, app: XCUIApplication) {
        let settings = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Настройки и диагностика",
                        "App settings and diagnostics")
        ).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        settings.tap()
        // Native SwiftUI Menu flattens Picker choices into the same menu:
        // English/Русский are buttons, not a second-level Picker control.
        let choice = app.buttons[locale]
        XCTAssertTrue(choice.waitForExistence(timeout: 7))
        choice.tap()
    }
}
