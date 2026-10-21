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

    func testSpanishDiagnosticsAndSettingsMenu() {
        checkDiagnostics(
            language: "es", locale: "es_ES",
            libraryButton: "Todas las notas", settings: "Ajustes y diagnóstico de la app",
            menuItem: "Diagnóstico de sincronización",
            title: "Diagnóstico de sincronización",
            recordings: "Grabaciones", pending: "Pendiente en el Watch",
            noQueueReport: "Aún no se ha recibido un informe de la cola del Watch."
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
        // iOS per-app language sets the interface. The persisted speech
        // recognition locale must not override diagnostics or the menu.
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
        // This view is a modal sheet, not a pushed navigation route.
        // A user must be able to close it without killing the application.
        let close = app.buttons["syncDiagnosticsClose"]
        XCTAssertTrue(close.waitForExistence(timeout: 6))
        close.tap()
        XCTAssertTrue(app.buttons[settings].waitForExistence(timeout: 7))
    }

    func testSpeechLanguageDoesNotSwitchInterfaceAndPersists() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Все заметки")
        ).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 15))
        library.tap()

        // Change on-device transcription to English through the actual menu,
        // without affecting the Russian locale chosen in iOS.
        selectLocale("Английский", app: app)
        XCTAssertTrue(app.buttons["Настройки и диагностика"]
                      .waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Ухват"].exists)

        let settings = app.buttons["Настройки и диагностика"]
        settings.tap()
        XCTAssertTrue(app.buttons["Язык интерфейса — в настройках iOS"]
                      .waitForExistence(timeout: 8))
        // Do not activate the system Settings link during UI tests.
        app.swipeDown()

        app.terminate()
        app.launch()
        let russianLibrary = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Все заметки")
        ).firstMatch
        XCTAssertTrue(russianLibrary.waitForExistence(timeout: 15))
        russianLibrary.tap()
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
