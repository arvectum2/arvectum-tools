import XCTest

/// SimplifiedChinese UI smoke with synthetic store and disabled iCloud sync.
final class SimplifiedChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSimplifiedChineseEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans_CN",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "稍后", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["创建习惯"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["从一个习惯开始"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["新习惯"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["习惯名称"].firstMatch.exists)
        XCTAssertTrue(app.buttons["完成"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-de-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
