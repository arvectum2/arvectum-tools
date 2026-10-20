import XCTest

/// Real UI smoke tests for the complete Spanish source pack.
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class SpanishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchSpanish(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable,
                          "Spanish consent must remain available without scrolling")
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        return app
    }

    @MainActor
    private func checkFlow(_ fixture: String, buttonLabel: String) {
        let app = launchSpanish(fixture)
        let process = app.buttons[buttonLabel]
        XCTAssertTrue(process.waitForExistence(timeout: 12),
                      "Spanish processing CTA not found: \(buttonLabel)")
        XCTAssertTrue(process.isHittable,
                      "Spanish processing CTA should not be clipped")
        process.tap()
        XCTAssertTrue(app.staticTexts["LISTO"].waitForExistence(timeout: 30),
                      "Spanish result title not shown")
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable,
                      "Spanish file-save action must be accessible")
        XCTAssertEqual(save.label, "Guardar archivo")
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "spanish-pdf-result" : "spanish-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testSpanishPhotoWorkflow() {
        checkFlow("--qa-photo-fixture", buttonLabel: "Comprimir foto")
    }

    @MainActor
    func testSpanishPDFWorkflow() {
        checkFlow("--qa-pdf-fixture", buttonLabel: "Comprimir PDF")
    }
}
