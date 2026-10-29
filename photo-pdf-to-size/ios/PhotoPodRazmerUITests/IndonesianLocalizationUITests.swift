import XCTest

/// Real iPhone UI smoke for the Indonesian source draft. Simulator-only synthetic
/// files, no account access, genuine ad requests or personal photo library.
final class IndonesianLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchIndonesian(_ fixture: String, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(id)", "-AppleLocale", "id_ID",
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
    func testIndonesianPhotoWorkflow() {
        let app = launchIndonesian("--qa-photo-fixture")
        let start = app.buttons["Perkecil foto"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        XCTAssertTrue(start.isHittable)
        start.tap()
        XCTAssertTrue(app.staticTexts["SELESAI"].waitForExistence(timeout: 30))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable)
        XCTAssertEqual(save.label, "Simpan berkas")
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "indonesian-photo-result"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testIndonesianPDFWorkflow() {
        let app = launchIndonesian("--qa-pdf-fixture")
        let start = app.buttons["Perkecil PDF"]
        XCTAssertTrue(start.waitForExistence(timeout: 12))
        XCTAssertTrue(start.isHittable)
        start.tap()
        XCTAssertTrue(app.staticTexts["SELESAI"].waitForExistence(timeout: 30))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertEqual(save.label, "Simpan berkas")
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "indonesian-pdf-result"
        capture.lifetime = .keepAlways
        add(capture)
    }

    @MainActor
    func testIndonesianLargeTextModeGridAndPrivacyConsent() {
        let app = launchIndonesian("--qa-photo-fixture", largeText: true)
        for (id, expected) in [
            ("mode-fileSize", "Kompres berkas"),
            ("mode-pixels", "Ubah ukuran foto"),
            ("mode-pdf", "Olah PDF")
        ] {
            let control = app.buttons[id]
            XCTAssertTrue(control.waitForExistence(timeout: 10), id)
            XCTAssertTrue(control.isHittable, id)
            XCTAssertEqual(control.label, expected, id)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        }
    }
}
