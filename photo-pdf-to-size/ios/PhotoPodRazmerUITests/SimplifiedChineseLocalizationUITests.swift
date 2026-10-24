import XCTest

/// Real UI smoke tests for the complete SimplifiedChinese source pack.
/// Synthetic input stays on the simulator; no production ad requests or file uploads.
final class SimplifiedChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    /// App Store version checks are live in older simulator builds. A newer
    /// public release can show this non-blocking prompt over the QA fixture.
    /// Dismiss only the update dialog, without disabling production behavior.
    @MainActor
    private func dismissOptionalUpdatePrompt(_ app: XCUIApplication) {
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@",
                        "Позже", "Later", "Más tarde", "Plus tard", "Später", "Più tardi", "後で", "稍后")
        ).firstMatch
        if later.waitForExistence(timeout: 8) {
            XCTAssertTrue(later.isHittable, "Optional update prompt must be dismissible")
            later.tap()
        }
    }

    @MainActor
    private func launchSimplifiedChinese(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans_CN",
            fixture
        ]
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 4) {
            XCTAssertTrue(decline.isHittable,
                          "SimplifiedChinese consent must remain available without scrolling")
            XCTAssertTrue(app.buttons["ad-consent-accept"].isHittable)
            decline.tap()
        }
        dismissOptionalUpdatePrompt(app)
        return app
    }

    @MainActor
    private func checkFlow(_ fixture: String, buttonLabel: String) {
        let app = launchSimplifiedChinese(fixture)
        let custom = app.buttons["自定义"]
        XCTAssertTrue(custom.waitForExistence(timeout: 8),
                      "SimplifiedChinese custom-size chip must have its short translated label")
        XCTAssertTrue(custom.isHittable, "SimplifiedChinese preset controls must be accessible")
        let process = app.buttons[buttonLabel]
        XCTAssertTrue(process.waitForExistence(timeout: 12),
                      "SimplifiedChinese processing CTA not found: \(buttonLabel)")
        XCTAssertTrue(process.isHittable,
                      "SimplifiedChinese processing CTA should not be clipped")
        process.tap()
        XCTAssertTrue(app.staticTexts["完成"].waitForExistence(timeout: 30),
                      "SimplifiedChinese result title not shown")
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isHittable,
                      "SimplifiedChinese file-save action must be accessible")
        XCTAssertEqual(save.label, "保存文件")
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "simplified-chinese-pdf-result" : "simplified-chinese-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testSimplifiedChineseAccessibilityModeGrid() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans_CN",
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
        XCTAssertEqual(first.label, "压缩文件")
        XCTAssertEqual(second.label, "调整照片尺寸")
        XCTAssertEqual(third.label, "证件照")
        XCTAssertEqual(fourth.label, "处理PDF")
        XCTAssertLessThan(abs(first.frame.minY - second.frame.minY), 12)
        XCTAssertGreaterThan(third.frame.minY, first.frame.minY + 44)
        XCTAssertLessThan(abs(third.frame.minY - fourth.frame.minY), 12)

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "simplified-chinese-axxxl-mode-grid"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    @MainActor
    func testSimplifiedChinesePhotoWorkflow() {
        checkFlow("--qa-photo-fixture", buttonLabel: "压缩照片")
    }

    @MainActor
    func testSimplifiedChinesePDFWorkflow() {
        checkFlow("--qa-pdf-fixture", buttonLabel: "压缩PDF")
    }
}
