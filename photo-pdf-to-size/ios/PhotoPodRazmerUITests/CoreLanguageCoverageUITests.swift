import XCTest

/// Russian/English baseline: real UI, synthetic photo, no user library/files.
/// Dedicated test cases close the iOS nine-language coverage matrix.
final class CoreLanguageCoverageUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func checkBaseline(
        language: String,
        locale: String,
        compress: String,
        resize: String,
        pdf: String
    ) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL",
            "--qa-photo-fixture"
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()

        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable)
            decline.tap()
        }
        // The optional App Store version prompt must remain dismissible.
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Позже", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }

        for (id, value) in [
            ("mode-fileSize", compress), ("mode-pixels", resize),
            ("mode-pdf", pdf)
        ] {
            let button = app.buttons[id]
            XCTAssertTrue(button.waitForExistence(timeout: 12), id)
            XCTAssertTrue(button.isHittable, id)
            XCTAssertEqual(button.label, value, id)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "photo-\(language)-baseline-axxxl"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testRussianBaselineAXXXLGrid() {
        checkBaseline(language: "ru", locale: "ru_RU",
                      compress: "Сжать файл", resize: "Изменить размер",
                      pdf: "Обработать PDF")
    }

    @MainActor
    func testEnglishBaselineAXXXLGrid() {
        checkBaseline(language: "en", locale: "en_US",
                      compress: "Compress file", resize: "Resize photo",
                      pdf: "Work with PDF")
    }
}
