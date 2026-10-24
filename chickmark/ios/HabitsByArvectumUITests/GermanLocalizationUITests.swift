import XCTest

/// German UI smoke with synthetic store and disabled iCloud sync.
final class GermanLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testGermanEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(de)", "-AppleLocale", "de_DE",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Später", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Gewohnheit erstellen"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Beginnen Sie mit einer Gewohnheit"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Neue Gewohnheit"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Name der Gewohnheit"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Fertig"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-de-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
