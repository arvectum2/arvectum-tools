import XCTest

/// EuropeanPortuguese UI smoke with synthetic store and disabled iCloud sync.
final class EuropeanPortugueseLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testEuropeanPortugueseEmptyStateAndNewHabitForm() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(pt-PT)", "-AppleLocale", "pt_PT",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Mais tarde", "Later")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        let create = app.buttons["Criar hábito"].firstMatch
        XCTAssertTrue(create.waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["Comece com um hábito"].exists)
        create.tap()
        XCTAssertTrue(app.navigationBars["Novo hábito"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.textFields["Nome do hábito"].firstMatch.exists)
        XCTAssertTrue(app.buttons["Concluído"].firstMatch.exists)
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "chickmark-ptpt-new-habit"
        image.lifetime = .keepAlways
        add(image)
    }
}
