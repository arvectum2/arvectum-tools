import XCTest

/// Real UI smoke tests for the complete German source pack.
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class GermanLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// App Store version checks are live in older simulator builds. A newer
    /// public release can show this non-blocking prompt over the QA fixture.
    /// Dismiss only the update dialog, without disabling production behavior.
    @MainActor
    private func dismissOptionalUpdatePrompt(_ app: XCUIApplication) {
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@",
                        "Позже", "Later", "Más tarde", "Plus tard", "Später")
        ).firstMatch
        if later.waitForExistence(timeout: 8) {
            XCTAssertTrue(later.isHittable, "Optional update prompt must be dismissible")
            later.tap()
        }
    }

    @MainActor
    private func launchGerman(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(de)", "-AppleLocale", "de_DE",
            fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable,
                          "German consent must remain available without scrolling")
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        dismissOptionalUpdatePrompt(app)
        return app
    }

    @MainActor
    private func checkFlow(_ fixture: String, buttonLabel: String) {
        let app = launchGerman(fixture)
        let custom = app.buttons["Eigene"]
        XCTAssertTrue(custom.waitForExistence(timeout: 8),
                      "German custom-size chip must have its short translated label")
        XCTAssertTrue(custom.isHittable, "German preset controls must be accessible")
        let process = app.buttons[buttonLabel]
        XCTAssertTrue(process.waitForExistence(timeout: 12),
                      "German processing CTA not found: \(buttonLabel)")
        XCTAssertTrue(process.isHittable,
                      "German processing CTA should not be clipped")
        process.tap()
        XCTAssertTrue(app.staticTexts["FERTIG"].waitForExistence(timeout: 30),
                      "German result title not shown")
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable,
                      "German file-save action must be accessible")
        XCTAssertEqual(save.label, "Datei speichern")
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "german-pdf-result" : "german-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testGermanAccessibilityModeGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(de)", "-AppleLocale", "de_DE",
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
        XCTAssertEqual(first.label, "Datei komprimieren")
        XCTAssertEqual(second.label, "Fotogröße ändern")
        XCTAssertEqual(third.label, "Passfoto")
        XCTAssertEqual(fourth.label, "PDF bearbeiten")
        XCTAssertLessThan(abs(first.frame.minY - second.frame.minY), 12)
        XCTAssertGreaterThan(third.frame.minY, first.frame.minY + 44)
        XCTAssertLessThan(abs(third.frame.minY - fourth.frame.minY), 12)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "german-axxxl-mode-grid"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testGermanPhotoWorkflow() {
        checkFlow("--qa-photo-fixture", buttonLabel: "Foto verkleinern")
    }

    @MainActor
    func testGermanPDFWorkflow() {
        checkFlow("--qa-pdf-fixture", buttonLabel: "PDF verkleinern")
    }
}
