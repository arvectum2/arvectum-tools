import XCTest

/// Full Turkish source-package smoke; isolated simulator data and no HealthKit writes.
final class TurkishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTurkishEmptyStateAndHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Alışkanlık oluştur"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Bir alışkanlıkla başla"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Yeni alışkanlık"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Alışkanlık adı"].firstMatch.exists)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "chickmark-tr-new-habit"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
