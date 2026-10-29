import XCTest

/// Real iPhone UI smoke for the Turkish source draft. Simulator-only synthetic
/// files, no account access, genuine ad requests or personal photo library.
final class TurkishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchTurkish(_ fixture: String, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR",
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
    func testTurkishPhotoWorkflow() {
        let app = launchTurkish("--qa-photo-fixture")
        let start = app.buttons["Fotoğrafı küçült"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        XCTAssertTrue(start.isHittable)
        start.tap()
        XCTAssertTrue(app.staticTexts["TAMAMLANDI"].waitForExistence(timeout: 30))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable)
        XCTAssertEqual(save.label, "Dosyayı kaydet")
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "turkish-photo-result"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testTurkishPDFWorkflow() {
        let app = launchTurkish("--qa-pdf-fixture")
        let start = app.buttons["PDF'yi küçült"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        XCTAssertTrue(start.isHittable)
        start.tap()
        XCTAssertTrue(app.staticTexts["TAMAMLANDI"].waitForExistence(timeout: 30))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertEqual(save.label, "Dosyayı kaydet")
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "turkish-pdf-result"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testTurkishLargeTextModeGridAndPrivacyConsent() {
        let app = launchTurkish("--qa-photo-fixture", largeText: true)
        for (id, expected) in [
            ("mode-fileSize", "Dosyayı sıkıştır"),
            ("mode-pixels", "Fotoğrafı yeniden boyutlandır"),
            ("mode-pdf", "PDF ile çalış")
        ] {
            let control = app.buttons[id]
            XCTAssertTrue(control.waitForExistence(timeout: 10), id)
            XCTAssertTrue(control.isHittable, id)
            XCTAssertEqual(control.label, expected, id)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        }
    }
}
