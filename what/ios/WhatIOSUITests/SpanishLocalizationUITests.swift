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

    /// A dedicated Debug-only UI fixture does not start AVFoundation or ask
    /// permission. The simulator can inspect real localized camera controls.
    @MainActor
    func testSpanishAXXXLVideoControlsWithoutCameraAccess() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-what.transcription.locale", "en-US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-video-controls-no-camera"
        ]
        app.launch()
        let videoAction = app.buttons["what.new.video"]
        XCTAssertTrue(videoAction.waitForExistence(timeout: 12))
        XCTAssertTrue(videoAction.isHittable)
        videoAction.tap()

        XCTAssertTrue(app.navigationBars["Nota de vídeo"]
                      .waitForExistence(timeout: 12))
        let discard = app.buttons["what.video.discard"]
        XCTAssertTrue(discard.waitForExistence(timeout: 10))
        XCTAssertEqual(discard.label, "Descartar")
        XCTAssertTrue(discard.isHittable)
        XCTAssertGreaterThanOrEqual(discard.frame.height, 44)
        let switchCamera = app.buttons["what.video.switchCamera"]
        XCTAssertTrue(switchCamera.exists)
        XCTAssertEqual(switchCamera.label, "Cambiar a cámara frontal")
        XCTAssertGreaterThanOrEqual(switchCamera.frame.width, 44)
        let stop = app.buttons["what.video.stop"]
        XCTAssertTrue(stop.exists)
        XCTAssertEqual(stop.label, "Detener y guardar")
        XCTAssertFalse(stop.isEnabled,
                       "The fixture must never begin camera capture")
        XCTAssertGreaterThanOrEqual(stop.frame.height, 44)

        discard.tap()
        XCTAssertTrue(app.buttons["what.record.primary"]
                      .waitForExistence(timeout: 12))
        XCTAssertFalse(app.alerts.firstMatch.exists,
                       "No camera permission should be requested")
    }

    /// Companion regression: the default font keeps the compact top-bar
    /// Discard and never triggers AVFoundation in its QA-only mode.
    @MainActor
    func testSpanishNormalSizeVideoKeepsNavigationDiscard() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM",
            "--qa-video-controls-normal-no-camera"
        ]
        app.launch()
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.waitForExistence(timeout: 12))
        video.tap()
        XCTAssertTrue(app.navigationBars["Nota de vídeo"]
                      .waitForExistence(timeout: 12))
        let discard = app.buttons["what.video.discard"]
        XCTAssertTrue(discard.waitForExistence(timeout: 10))
        XCTAssertTrue(discard.isHittable)
        XCTAssertEqual(discard.label, "Descartar")
        XCTAssertLessThan(discard.frame.minY, 160,
                          "Regular font should keep Discard in the navigation bar")
        let stop = app.buttons["what.video.stop"]
        XCTAssertTrue(stop.exists)
        XCTAssertFalse(stop.isEnabled, "No camera may start in layout QA")
        discard.tap()
        XCTAssertTrue(app.buttons["what.record.primary"]
                      .waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    @MainActor
    func testSpanishAXXXLAudioControlsWithoutMicrophoneAccess() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "-what.transcription.locale", "en-US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-audio-controls-no-microphone"
        ]
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 12))
        home.tap()

        XCTAssertTrue(app.navigationBars["Nueva grabación"]
                      .waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Nota de voz"].exists)
        let close = app.buttons["what.audio.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertEqual(close.label, "Cerrar")
        XCTAssertTrue(close.isHittable)
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        let start = app.buttons["what.audio.start"]
        XCTAssertTrue(start.exists)
        XCTAssertEqual(start.label, "Iniciar grabación")
        XCTAssertFalse(start.isEnabled,
                       "Debug fixture must never activate microphone")
        XCTAssertGreaterThanOrEqual(start.frame.height, 44)
        close.tap()
        XCTAssertTrue(home.waitForExistence(timeout: 12))
        XCTAssertFalse(app.alerts.firstMatch.exists,
                       "Debug layout QA must not request mic permissions")
    }

    @MainActor
    func testSpanishNormalSizeAudioPreservesNavigationClose() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryM",
            "--qa-audio-controls-normal-no-microphone"
        ]
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 12))
        home.tap()
        XCTAssertTrue(app.navigationBars["Nueva grabación"]
                      .waitForExistence(timeout: 10))
        let close = app.buttons["what.audio.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        XCTAssertEqual(close.label, "Cerrar")
        XCTAssertTrue(close.isHittable)
        XCTAssertLessThan(close.frame.minY, 160,
                          "Normal font must retain navigation toolbar")
        XCTAssertFalse(app.buttons["what.audio.start"].isEnabled)
        close.tap()
        XCTAssertTrue(home.waitForExistence(timeout: 10))
        XCTAssertFalse(app.alerts.firstMatch.exists)
    }

    /// Isolated in-memory transcript fixture; no recording, repo access,
    /// microphone permission or saved transcription can be modified.
    @MainActor
    func testSpanishAXXXLTranscriptActionsReachableWithoutSaving() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-transcript-editor-synthetic"
        ]
        app.launch()
        let open = app.buttons["what.qa.transcript.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 12))
        open.tap()

        XCTAssertTrue(app.navigationBars["Editar transcripción"]
                      .waitForExistence(timeout: 12))
        let text = app.textViews["what.transcript.editor"]
        XCTAssertTrue(text.waitForExistence(timeout: 12))
        XCTAssertEqual(text.label, "Transcripción de la grabación")
        XCTAssertTrue(text.isHittable)

        let cancel = app.buttons["what.transcript.cancel"]
        let save = app.buttons["what.transcript.save"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        XCTAssertTrue(save.exists)
        XCTAssertEqual(cancel.label, "Cancelar")
        XCTAssertEqual(save.label, "Guardar")
        XCTAssertTrue(cancel.isHittable)
        XCTAssertGreaterThanOrEqual(cancel.frame.height, 44)
        XCTAssertGreaterThanOrEqual(save.frame.height, 44)
        XCTAssertFalse(save.isEnabled, "Synthetic draft has no changes")
        cancel.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 10))
    }

    @MainActor
    func testSpanishAXXXLSyntheticTranscriptEditEnablesSaveWithoutDiskWrite() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "--qa-transcript-editor-synthetic"
        ]
        app.launch()
        let open = app.buttons["what.qa.transcript.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 12))
        open.tap()
        let save = app.buttons["what.transcript.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertFalse(save.isEnabled)
        let editor = app.textViews["what.transcript.editor"]
        XCTAssertTrue(editor.exists)
        editor.tap()
        editor.typeText(" actualizado")
        XCTAssertTrue(save.isEnabled,
                      "Changed local draft should enable Save")
        XCTAssertGreaterThanOrEqual(save.frame.height, 44)
        // QA-only onSave closure is a no-op, so no recording is stored.
        save.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 10))
    }

    @MainActor
    func testSpanishNormalTranscriptKeepsToolbarAndSafeCancel() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "--qa-transcript-editor-synthetic-normal"
        ]
        app.launch()
        let open = app.buttons["what.qa.transcript.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 12))
        open.tap()
        XCTAssertTrue(app.navigationBars["Editar transcripción"]
                      .waitForExistence(timeout: 12))
        let cancel = app.buttons["what.transcript.cancel"]
        let save = app.buttons["what.transcript.save"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 10))
        XCTAssertEqual(cancel.label, "Cancelar")
        XCTAssertTrue(cancel.isHittable)
        XCTAssertLessThan(cancel.frame.minY, 160,
                          "Regular font preserves the navigation Cancel")
        XCTAssertTrue(save.exists)
        XCTAssertFalse(save.isEnabled)
        cancel.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 10))
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
