import XCTest

/// French smoke using ChickMark's synthetic UI test store, never a real iCloud account.
final class FrenchLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testFrenchEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(fr)",
            "-AppleLocale", "fr_FR",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()

        let create = app.buttons["Créer une habitude"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Commencez par une habitude"].exists)
        create.tap()

        XCTAssertTrue(app.navigationBars["Nouvelle habitude"]
            .firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Nom de l’habitude"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Terminé"].firstMatch.exists)

        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-fr-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
