import XCTest

/// Korean automated DRAFT: simulator's disposable synthetic store and CloudKit disabled.
final class KoreanLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testKoreanEmptyStateAndNewHabit() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "나중에", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["습관 만들기"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["습관 하나부터 시작하세요"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["새 습관"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["습관 이름"].firstMatch.exists)
        XCTAssertTrue(app.buttons["완료"].firstMatch.exists)
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "chickmark-ko-new-habit"
        evidence.lifetime = .keepAlways
        add(evidence)
    }
}
