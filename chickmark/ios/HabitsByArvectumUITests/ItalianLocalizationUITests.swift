import XCTest

/// Italian UI smoke with synthetic store and disabled iCloud sync.
final class ItalianLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testItalianEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(it)", "-AppleLocale", "it_IT",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Più tardi", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Crea abitudine"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Inizia con un'abitudine"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Nuova abitudine"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Nome dell'abitudine"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Fine"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-de-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
