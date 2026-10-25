import XCTest

/// TraditionalChinese UI smoke with synthetic store and disabled iCloud sync.
final class TraditionalChineseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTraditionalChineseEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(zh-Hant)", "-AppleLocale", "zh_Hant_TW",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "稍後", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["建立習慣"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["從一個習慣開始"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["新習慣"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["習慣名稱"].firstMatch.exists)
        XCTAssertTrue(app.buttons["完成"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-de-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
