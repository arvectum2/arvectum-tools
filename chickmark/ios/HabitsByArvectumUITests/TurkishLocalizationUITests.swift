import XCTest

/// Turkish iPhone simulator QA: isolated empty SwiftData, no CloudKit or HealthKit mutations.
final class TurkishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTurkishEmptyStateAndNewHabitForm() {
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
        XCTAssertTrue(app.staticTexts["Tek bir alışkanlıkla başlayın"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Yeni alışkanlık"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Alışkanlık adı"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Bitti"].firstMatch.exists)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "chickmark-nl-new-habit"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
