import XCTest

final class HabitFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing"
        ]
        app.launch()
    }

    func testCreateCheckAndOpenHistory() throws {
        let createButton = app.buttons["Create habit"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        createButton.tap()

        let newHabitBar = app.navigationBars["New habit"]
        XCTAssertTrue(newHabitBar.waitForExistence(timeout: 3))

        let nameField = app.textFields[
            "For example, read for 20 minutes"
        ]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.typeText("Read")

        let doneButton = newHabitBar.buttons["Done"]
        XCTAssertTrue(doneButton.isEnabled)
        doneButton.tap()

        let habitName = app.staticTexts["Read"].firstMatch
        XCTAssertTrue(habitName.waitForExistence(timeout: 3))

        let completeButton = app.buttons["Mark complete"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: 3))
        completeButton.tap()

        XCTAssertTrue(
            app.buttons["Undo completion"].waitForExistence(timeout: 3)
        )

        habitName.tap()

        XCTAssertTrue(
            app.navigationBars["Read"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.staticTexts["Last 5 weeks"].waitForExistence(timeout: 3)
        )
    }
}
