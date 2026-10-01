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
            app.staticTexts["Last 6 weeks"].waitForExistence(timeout: 3)
        )
    }


    func testManageShowsScheduleWithoutOpeningEachHabit() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--seed-watch-sync-demo",
            "--disable-cloud-sync"
        ]
        app.launch()

        let manageButton = app.buttons["Manage habits"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 3))
        XCTAssertTrue(manageButton.isHittable)
        manageButton.tap()

        XCTAssertTrue(
            app.navigationBars["Manage habits"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Water"].waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(
            app.staticTexts.matching(
                NSPredicate(format: "label == %@", "Every day")
            ).count,
            2
        )
    }

    func testFlexibleWeeklyGoalIsReadableOnTodayAndManage() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--seed-flexible-weekly-demo",
            "--disable-cloud-sync"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts["Workout"].waitForExistence(timeout: 3))
        XCTAssertTrue(
            app.staticTexts["0 of 3 this week"].waitForExistence(timeout: 3)
        )

        let manageButton = app.buttons["Manage habits"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 3))
        manageButton.tap()

        XCTAssertTrue(
            app.staticTexts["3 times per week"].waitForExistence(timeout: 3)
        )
    }

    func testCoreCreationFlowAtLargestDynamicType() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--ui-testing"
        ]
        app.launch()

        let createButton = app.buttons["Create habit"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        XCTAssertTrue(createButton.isHittable)
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
        XCTAssertTrue(doneButton.isHittable)
        doneButton.tap()

        XCTAssertTrue(
            app.staticTexts["Read"].firstMatch.waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.buttons["Mark complete"].waitForExistence(timeout: 3)
        )
    }
}
