import XCTest

/// Dutch iPhone simulator QA: isolated empty SwiftData, no CloudKit or HealthKit mutations.
final class DutchLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testDutchEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(nl)", "-AppleLocale", "nl_NL",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Gewoonte aanmaken"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Begin met één gewoonte"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Nieuwe gewoonte"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Naam van gewoonte"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Gereed"].firstMatch.exists)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "chickmark-nl-new-habit"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
