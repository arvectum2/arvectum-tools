import XCTest

/// Real iPhone UI smoke for the Dutch source draft. Simulator-only synthetic
/// files, no account access, genuine ad requests or personal photo library.
final class DutchLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchDutch(_ fixture: String, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(nl)", "-AppleLocale", "nl_NL",
            fixture
        ]
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 5) {
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            XCTAssertTrue(decline.isHittable)
            decline.tap()
        }
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Позже", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        return app
    }

    @MainActor
    func testDutchPhotoWorkflow() {
        let app = launchDutch("--qa-photo-fixture")
        let start = app.buttons["Foto verkleinen"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        XCTAssertTrue(start.isHittable)
        start.tap()
        XCTAssertTrue(app.staticTexts["GEREED"].waitForExistence(timeout: 30))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable)
        XCTAssertEqual(save.label, "Bestand opslaan")
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "dutch-photo-result"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testDutchPDFWorkflow() {
        let app = launchDutch("--qa-pdf-fixture")
        let start = app.buttons["PDF verkleinen"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        XCTAssertTrue(start.isHittable)
        start.tap()
        XCTAssertTrue(app.staticTexts["GEREED"].waitForExistence(timeout: 30))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertEqual(save.label, "Bestand opslaan")
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "dutch-pdf-result"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testDutchLargeTextModeGridAndPrivacyConsent() {
        let app = launchDutch("--qa-photo-fixture", largeText: true)
        for (id, expected) in [
            ("mode-fileSize", "Bestand comprimeren"),
            ("mode-pixels", "Fotoformaat wijzigen"),
            ("mode-pdf", "Werken met PDF")
        ] {
            let control = app.buttons[id]
            XCTAssertTrue(control.waitForExistence(timeout: 10), id)
            XCTAssertTrue(control.isHittable, id)
            XCTAssertEqual(control.label, expected, id)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        }
    }
}
