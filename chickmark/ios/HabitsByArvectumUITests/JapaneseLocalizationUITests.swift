import XCTest

/// Japanese UI smoke with synthetic store and disabled iCloud sync.
final class JapaneseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testJapaneseEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "後で", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["習慣を作成"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["習慣を1つ始めましょう"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["新しい習慣"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["習慣の名前"].firstMatch.exists)
        XCTAssertTrue(app.buttons["完了"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-de-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
