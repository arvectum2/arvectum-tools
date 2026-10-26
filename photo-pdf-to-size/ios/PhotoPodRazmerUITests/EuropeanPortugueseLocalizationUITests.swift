import XCTest

/// Real UI smoke tests for the European Portuguese draft source pack (editorial sign-off pending).
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class EuropeanPortugueseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// App Store version checks are live in older simulator builds. A newer
    /// public release can show this non-blocking prompt over the QA fixture.
    /// Dismiss only the update dialog, without disabling production behavior.
    @MainActor
    private func dismissOptionalUpdatePrompt(_ app: XCUIApplication) {
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@",
                        "Позже", "Later", "Más tarde", "Plus tard", "Mais tarde")
        ).firstMatch
        if later.waitForExistence(timeout: 8) {
            XCTAssertTrue(later.isHittable, "Optional update prompt must be dismissible")
            later.tap()
        }
    }

    @MainActor
    private func launchEuropeanPortuguese(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(pt-PT)", "-AppleLocale", "pt_PT",
            fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable,
                          "EuropeanPortuguese consent must remain available without scrolling")
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        dismissOptionalUpdatePrompt(app)
        return app
    }

    @MainActor
    private func checkFlow(_ fixture: String, buttonLabel: String) {
        let app = launchEuropeanPortuguese(fixture)
        let custom = app.buttons["Outro"]
        XCTAssertTrue(custom.waitForExistence(timeout: 8),
                      "EuropeanPortuguese custom-size chip must have its short translated label")
        XCTAssertTrue(custom.isHittable, "EuropeanPortuguese preset controls must be accessible")
        let process = app.buttons[buttonLabel]
        XCTAssertTrue(process.waitForExistence(timeout: 12),
                      "EuropeanPortuguese processing CTA not found: \(buttonLabel)")
        XCTAssertTrue(process.isHittable,
                      "EuropeanPortuguese processing CTA should not be clipped")
        process.tap()
        XCTAssertTrue(app.staticTexts["PRONTO"].waitForExistence(timeout: 30),
                      "EuropeanPortuguese result title not shown")
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable,
                      "EuropeanPortuguese file-save action must be accessible")
        XCTAssertEqual(save.label, "Guardar ficheiro")
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "european-portuguese-pdf-result" : "european-portuguese-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testEuropeanPortugueseAccessibilityModeGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(pt-PT)", "-AppleLocale", "pt_PT",
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
        XCTAssertEqual(first.label, "Compactar ficheiro")
        XCTAssertEqual(second.label, "Redimensionar fotografia")
        XCTAssertEqual(third.label, "Fotografia para documento")
        XCTAssertEqual(fourth.label, "Trabalhar com PDF")
        XCTAssertLessThan(abs(first.frame.minY - second.frame.minY), 12)
        XCTAssertGreaterThan(third.frame.minY, first.frame.minY + 44)
        XCTAssertLessThan(abs(third.frame.minY - fourth.frame.minY), 12)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "european-portuguese-axxxl-mode-grid"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testEuropeanPortuguesePhotoWorkflow() {
        checkFlow("--qa-photo-fixture", buttonLabel: "Reduzir fotografia")
    }

    @MainActor
    func testEuropeanPortuguesePDFWorkflow() {
        checkFlow("--qa-pdf-fixture", buttonLabel: "Reduzir PDF")
    }
}
