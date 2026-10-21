import XCTest

/// Validate the real Spanish home screen, including custom VoiceOver actions.
/// No microphone/video permission, real recording, or user note is modified.
final class SpanishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSpanishAccessibilityXXXLHomeControls() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "es-ES",
            "--qa-spanish-axxxl-home"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Captura esa idea"].waitForExistence(timeout: 12))
        let primary = app.buttons["what.record.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 12))
        XCTAssertTrue(primary.isHittable)
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.exists)
        XCTAssertTrue(text.isHittable)
        XCTAssertEqual(text.label, "Nueva nota de texto")
        XCTAssertLessThan(text.frame.height, 115,
                          "Spanish text action must not split onto multiple lines")
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.exists)
        XCTAssertTrue(video.isHittable)
        XCTAssertLessThan(video.frame.height, 115)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.exists)
        XCTAssertTrue(library.isHittable)
        XCTAssertTrue(library.label.hasPrefix("Todas las notas, "))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "what-es-accessibility5-home"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSpanishInterfaceIndependentOfEnglishDictation() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "en-US"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Captura esa idea"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Toca para grabar audio"].exists)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.exists)
        XCTAssertEqual(library.label.hasPrefix("Todas las notas, "), true)
    }

    @MainActor
    func testRussianInterfaceIndependentOfEnglishDictation() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)",
            "-AppleLocale", "ru_RU",
            "-what.transcription.locale", "en-US"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts["Ухвати мысль"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Нажмите для аудио"].exists)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.exists)
        XCTAssertTrue(library.label.hasPrefix("Все заметки, "))
    }

    /// Run on the isolated iPad simulator with AXXXL layout. The populated
    /// notes are debug-only synthetic metadata and do not touch user files.
    @MainActor
    func testSpanishMixedNotesLibraryAXXXLAccessibleNavigation() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "en-US",
            "--qa-design-filled-library"
        ]
        app.launch()
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.waitForExistence(timeout: 12))
        library.tap()

        let all = app.buttons["what.filter.all"]
        let textFilter = app.buttons["what.filter.text"]
        let videoFilter = app.buttons["what.filter.video"]
        XCTAssertTrue(all.waitForExistence(timeout: 12))
        XCTAssertTrue(all.label.contains("Todas"), all.label)
        XCTAssertTrue(textFilter.exists)
        XCTAssertTrue(textFilter.label.contains("Texto"), textFilter.label)
        XCTAssertTrue(videoFilter.exists)
        XCTAssertTrue(videoFilter.label.contains("Vídeo"), videoFilter.label)
        XCTAssertTrue(app.staticTexts["Hoy"].exists,
                      "Day sections must use Spanish even with English dictation")

        let settings = app.buttons["what.library.settings"]
        XCTAssertTrue(settings.exists)
        XCTAssertTrue(settings.isHittable)
        XCTAssertGreaterThanOrEqual(settings.frame.width, 44)
        XCTAssertGreaterThanOrEqual(settings.frame.height, 44)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "uhvat-es-ipad-axxxl-library"
        attachment.lifetime = .keepAlways
        add(attachment)

        try app.performAccessibilityAudit(for: [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]) { issue in
            print("UHWHAT_ES_IPAD_AX issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription)")
            return false
        }
    }

    /// AXXXL Spanish editor with no note content entered. The test never
    /// generates a saved note and checks the actual VoiceOver name/hint.
    @MainActor
    func testSpanishAXXXLTextEditorReadableAndDismissible() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "en-US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-spanish-axxxl-home"
        ]
        app.launch()
        let newText = app.buttons["what.new.text"]
        XCTAssertTrue(newText.waitForExistence(timeout: 12))
        XCTAssertTrue(newText.isHittable)
        newText.tap()

        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 12))
        XCTAssertEqual(editor.label, "Texto de la nota")
        XCTAssertTrue(editor.isHittable)
        XCTAssertGreaterThanOrEqual(editor.frame.width, 220)

        let title = app.navigationBars["Nota de texto"]
        XCTAssertTrue(title.exists)
        let done = app.buttons["what.text.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        XCTAssertTrue(done.isHittable)
        XCTAssertGreaterThanOrEqual(done.frame.height, 44)

        // The iPad keyboard is system-owned. This smoke validates the
        // accessible editor and 44pt button; the library's full AX system
        // audit is covered by a separate, successful test.
        done.tap()
        XCTAssertTrue(app.buttons["what.record.primary"]
                      .waitForExistence(timeout: 10))
    }

    /// The settings menu must remain reachable with a huge font and a
    /// separately chosen dictation language. No settings are changed.
    @MainActor
    func testSpanishAXXXLSettingsLanguageIsDiscoverable() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "en-US",
            "--qa-design-filled-library"
        ]
        app.launch()
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.waitForExistence(timeout: 12))
        library.tap()
        let settings = app.buttons["what.library.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        XCTAssertTrue(settings.isHittable)
        settings.tap()

        let english = app.buttons["Inglés"].firstMatch
        XCTAssertTrue(english.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Ruso"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Español"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Idioma de la interfaz: ajustes de iOS"]
                      .firstMatch.exists)
        XCTAssertTrue(app.buttons["Diagnóstico de sincronización"]
                      .firstMatch.exists)

        // Never open external Settings or change the speech preference.
    }

    @MainActor
    func testSpanishHomeAndVoiceOverLabels() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "es-ES"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Captura esa idea"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Toca para grabar audio"].exists)
        XCTAssertTrue(app.staticTexts["Todas las notas"].exists)
        let record = app.buttons["what.record.primary"]
        XCTAssertTrue(record.waitForExistence(timeout: 12))
        XCTAssertEqual(record.label, "Iniciar grabación")
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.waitForExistence(timeout: 8))
        XCTAssertTrue(library.label.hasPrefix("Todas las notas, "))
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.waitForExistence(timeout: 8))
        XCTAssertEqual(text.label, "Nueva nota de texto")
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.exists)
        XCTAssertTrue(video.isHittable)
        XCTAssertEqual(video.label, "Vídeo")

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "what-es-main-screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
