import XCTest

/// SimplifiedChinese UI smoke with synthetic in-app QA state: no actual audio is recorded.
final class SimplifiedChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSimplifiedChineseXXXLHomeControlsWithoutRecording() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans_CN",
            "-what.transcription.locale", "en-US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-spanish-axxxl-home"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "稍后", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        XCTAssertTrue(app.staticTexts["记下你的想法"].waitForExistence(timeout: 12))
        let primary = app.buttons["what.record.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 12))
        XCTAssertTrue(primary.isHittable)
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.isHittable)
        XCTAssertEqual(text.label, "新建文字笔记")
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.isHittable)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.isHittable)
        XCTAssertTrue(library.label.hasPrefix("全部笔记，"), library.label)
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "uhvat-de-home-axxxl"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
