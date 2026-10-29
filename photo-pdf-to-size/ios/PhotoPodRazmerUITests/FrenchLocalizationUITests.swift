import XCTest

/// Real UI smoke tests for the complete French source pack.
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class FrenchLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// App Store version checks are live in older simulator builds. A newer
    /// public release can show this non-blocking prompt over the QA fixture.
    /// Dismiss only the update dialog, without disabling production behavior.
    @MainActor
    private func dismissOptionalUpdatePrompt(_ app: XCUIApplication) {
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@",
                        "Позже", "Later", "Más tarde", "Plus tard")
        ).firstMatch
        if later.waitForExistence(timeout: 8) {
            XCTAssertTrue(later.isHittable, "Optional update prompt must be dismissible")
            later.tap()
        }
    }

    @MainActor
    private func launchFrench(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR",
            fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable,
                          "French consent must remain available without scrolling")
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        dismissOptionalUpdatePrompt(app)
        return app
    }

    @MainActor
    private func checkFlow(_ fixture: String, buttonLabel: String) {
        let app = launchFrench(fixture)
        let process = app.buttons[buttonLabel]
        XCTAssertTrue(process.waitForExistence(timeout: 12),
                      "French processing CTA not found: \(buttonLabel)")
        XCTAssertTrue(process.isHittable,
                      "French processing CTA should not be clipped")
        process.tap()
        XCTAssertTrue(app.staticTexts["TERMINÉ"].waitForExistence(timeout: 30),
                      "French result title not shown")
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable,
                      "French file-save action must be accessible")
        XCTAssertEqual(save.label, "Enregistrer le fichier")
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "french-pdf-result" : "french-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testFrenchAccessibilityModeGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR",
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
        XCTAssertEqual(first.label, "Compresser le fichier")
        XCTAssertEqual(second.label, "Redimensionner la photo")
        XCTAssertEqual(third.label, "Photo d’identité")
        XCTAssertEqual(fourth.label, "Traiter un PDF")
        XCTAssertLessThan(abs(first.frame.minY - second.frame.minY), 12)
        XCTAssertGreaterThan(third.frame.minY, first.frame.minY + 44)
        XCTAssertLessThan(abs(third.frame.minY - fourth.frame.minY), 12)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "french-axxxl-mode-grid"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testFrenchPhotoWorkflow() {
        checkFlow("--qa-photo-fixture", buttonLabel: "Réduire la photo")
    }

    @MainActor
    func testFrenchPDFWorkflow() {
        checkFlow("--qa-pdf-fixture", buttonLabel: "Réduire le PDF")
    }

    /// Regression for the FR AXXXL source-picker title: it previously
    /// rendered “Photo sé…” even though the full accessibility label existed.
    @MainActor
    func testFrenchAccessibilitySelectedPhotoText() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(fr)", "-AppleLocale", "fr_FR",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL",
            "--qa-photo-fixture"
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 3) { decline.tap() }
        dismissOptionalUpdatePrompt(app)

        let fullTitle = app.staticTexts["Photo et PDF aux bonnes dimensions"].firstMatch
        XCTAssertTrue(fullTitle.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(fullTitle.frame.height, 32,
                             "The long French header must wrap at accessibility sizes")

        let photoTitle = app.staticTexts["Photo sélectionnée"].firstMatch
        XCTAssertTrue(photoTitle.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(photoTitle.frame.height, 80,
                             "The full picker title needs two readable lines")
        let contentScroll = app.scrollViews.firstMatch
        XCTAssertTrue(contentScroll.exists)
        // A full-page swipe overshoots the picker; move within the card
        // by a fraction of the scroll-view height instead.
        let from = contentScroll.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.77)
        )
        let to = contentScroll.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.48)
        )
        from.press(forDuration: 0.1, thenDragTo: to)
        XCTAssertTrue(photoTitle.isHittable,
                      "The full French photo picker title must stay scroll-accessible")
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "french-axxxl-photo-picker-after-scroll"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
