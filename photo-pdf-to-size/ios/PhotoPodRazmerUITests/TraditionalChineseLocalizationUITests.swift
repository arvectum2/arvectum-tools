import XCTest

/// Real UI smoke tests for the complete TraditionalChinese source pack.
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class TraditionalChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// App Store version checks are live in older simulator builds. A newer
    /// public release can show this non-blocking prompt over the QA fixture.
    /// Dismiss only the update dialog, without disabling production behavior.
    @MainActor
    private func dismissOptionalUpdatePrompt(_ app: XCUIApplication) {
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@",
                        "Позже", "Later", "Más tarde", "Plus tard", "Später", "Più tardi", "後で", "稍後")
        ).firstMatch
        if later.waitForExistence(timeout: 8) {
            XCTAssertTrue(later.isHittable, "Optional update prompt must be dismissible")
            later.tap()
        }
    }

    @MainActor
    private func launchTraditionalChinese(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_Hant_TW",
            fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable,
                          "TraditionalChinese consent must remain available without scrolling")
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        dismissOptionalUpdatePrompt(app)
        return app
    }

    @MainActor
    private func checkFlow(_ fixture: String, buttonLabel: String) {
        let app = launchTraditionalChinese(fixture)
        let custom = app.buttons["自定義"]
        XCTAssertTrue(custom.waitForExistence(timeout: 8),
                      "TraditionalChinese custom-size chip must have its short translated label")
        XCTAssertTrue(custom.isHittable, "TraditionalChinese preset controls must be accessible")
        let process = app.buttons[buttonLabel]
        XCTAssertTrue(process.waitForExistence(timeout: 12),
                      "TraditionalChinese processing CTA not found: \(buttonLabel)")
        XCTAssertTrue(process.isHittable,
                      "TraditionalChinese processing CTA should not be clipped")
        process.tap()
        XCTAssertTrue(app.staticTexts["完成"].waitForExistence(timeout: 30),
                      "TraditionalChinese result title not shown")
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable,
                      "TraditionalChinese file-save action must be accessible")
        XCTAssertEqual(save.label, "儲存檔案")
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "simplified-chinese-pdf-result" : "simplified-chinese-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testTraditionalChineseAccessibilityModeGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_Hant_TW",
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
        XCTAssertEqual(first.label, "壓縮檔案")
        XCTAssertEqual(second.label, "調整照片尺寸")
        XCTAssertEqual(third.label, "證件照")
        XCTAssertEqual(fourth.label, "處理PDF")
        XCTAssertLessThan(abs(first.frame.minY - second.frame.minY), 12)
        XCTAssertGreaterThan(third.frame.minY, first.frame.minY + 44)
        XCTAssertLessThan(abs(third.frame.minY - fourth.frame.minY), 12)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "simplified-chinese-axxxl-mode-grid"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testTraditionalChinesePhotoWorkflow() {
        checkFlow("--qa-photo-fixture", buttonLabel: "壓縮照片")
    }

    @MainActor
    func testTraditionalChinesePDFWorkflow() {
        checkFlow("--qa-pdf-fixture", buttonLabel: "壓縮PDF")
    }
}
