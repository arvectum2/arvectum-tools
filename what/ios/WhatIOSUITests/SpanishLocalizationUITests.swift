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
