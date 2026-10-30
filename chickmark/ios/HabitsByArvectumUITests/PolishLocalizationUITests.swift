import XCTest

/// Polish iPhone smoke using isolated synthetic storage. No HealthKit writes.
final class PolishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPolishEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Utwórz nawyk"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Zacznij od jednego nawyku"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Nowy nawyk"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Nazwa nawyku"].firstMatch.exists)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "chickmark-pl-new-habit"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
