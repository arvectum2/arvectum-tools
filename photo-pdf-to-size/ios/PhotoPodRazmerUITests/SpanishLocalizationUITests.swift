import XCTest

/// Real UI smoke tests for the complete Spanish source pack.
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class SpanishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// App Store version checks are live in older simulator builds. A newer
    /// public release can show this non-blocking prompt over the QA fixture.
    /// Dismiss only the update dialog, without disabling production behavior.
    @MainActor
    private func dismissOptionalUpdatePrompt(_ app: XCUIApplication) {
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Позже", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 8) {
            XCTAssertTrue(later.isHittable, "Optional update prompt must be dismissible")
            later.tap()
        }
    }

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
        dismissOptionalUpdatePrompt(app)
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
    func testSpanishAccessibilityModeGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(es)", "-AppleLocale", "es_ES",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL",
            "--qa-photo-fixture"
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 3) { decline.tap() }
        dismissOptionalUpdatePrompt(app)

        let first = app.buttons["mode-fileSize"]
        let second = app.buttons["mode-pixels"]
        let third = app.buttons["mode-passport"]
        let fourth = app.buttons["mode-pdf"]
        for button in [first, second, third, fourth] {
            XCTAssertTrue(button.waitForExistence(timeout: 8))
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        }
        XCTAssertEqual(first.label, "Comprimir archivo")
        XCTAssertEqual(second.label, "Cambiar tamaño de la foto")
        XCTAssertEqual(third.label, "Foto para documento")
        XCTAssertEqual(fourth.label, "Trabajar con PDF")
        XCTAssertLessThan(abs(first.frame.minY - second.frame.minY), 12)
        XCTAssertGreaterThan(third.frame.minY, first.frame.minY + 44)
        XCTAssertLessThan(abs(third.frame.minY - fourth.frame.minY), 12)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "spanish-axxxl-mode-grid"
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
