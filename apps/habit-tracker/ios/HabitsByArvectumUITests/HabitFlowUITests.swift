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

    func testStorageFailureShowsNonDestructiveRecoveryScreen() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--simulate-storage-recovery"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Habits data is temporarily unavailable"]
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(app.buttons["Create habit"].exists)
    }

    func testDeepLinkRouteOpensHabitDetail() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--seed-watch-sync-demo",
            "--disable-cloud-sync",
            "--debug-open-reading-deeplink"
        ]
        app.launch()

        XCTAssertTrue(
            app.navigationBars["Reading"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.staticTexts["Last 6 weeks"].waitForExistence(timeout: 3)
        )
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
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
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


    func testSkipThenCompleteClearsNeutralSkipState() throws {
        launchSeededDemo()

        let reading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 3))
        reading.tap()

        let skipButton = app.buttons["Skip today"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 3))
        XCTAssertTrue(skipButton.isHittable)
        skipButton.tap()

        XCTAssertTrue(
            app.buttons["Undo skip"].waitForExistence(timeout: 3)
        )

        app.navigationBars["Reading"].buttons["Today"].tap()

        XCTAssertTrue(
            app.staticTexts["Skipped today"].waitForExistence(timeout: 3)
        )

        let completeButton = app.buttons["Mark complete"].firstMatch
        XCTAssertTrue(completeButton.waitForExistence(timeout: 3))
        completeButton.tap()

        XCTAssertTrue(
            app.buttons["Undo completion"].firstMatch
                .waitForExistence(timeout: 3)
        )
        XCTAssertFalse(app.staticTexts["Skipped today"].exists)
    }

    func testPauseAndResumeMovesHabitOutOfAndBackIntoToday() throws {
        launchSeededDemo()

        let reading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 3))
        reading.tap()

        let moreButton = app.buttons["More habit actions"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 3))
        moreButton.tap()

        let pauseButton = app.buttons["Pause habit"]
        XCTAssertTrue(pauseButton.waitForExistence(timeout: 3))
        pauseButton.tap()

        XCTAssertTrue(
            app.buttons["Resume habit"].waitForExistence(timeout: 3)
        )

        app.navigationBars["Reading"].buttons["Today"].tap()
        XCTAssertFalse(app.staticTexts["Reading"].exists)

        let manageButton = app.buttons["Manage habits"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 3))
        manageButton.tap()

        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 3))
        let pausedReading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(pausedReading.waitForExistence(timeout: 3))
        pausedReading.tap()

        let resumeButton = app.buttons["Resume habit"]
        XCTAssertTrue(resumeButton.waitForExistence(timeout: 3))
        resumeButton.tap()

        app.navigationBars["Reading"].buttons["Manage habits"].tap()
        XCTAssertTrue(app.staticTexts["Active"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 3))
    }

    func testArchiveAndRestoreKeepsHabitRecoverable() throws {
        launchSeededDemo()

        let reading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 3))
        reading.tap()

        let moreButton = app.buttons["More habit actions"]
        XCTAssertTrue(moreButton.waitForExistence(timeout: 3))
        moreButton.tap()

        let archiveButton = app.buttons["Archive"]
        XCTAssertTrue(archiveButton.waitForExistence(timeout: 3))
        archiveButton.tap()

        XCTAssertFalse(app.staticTexts["Reading"].exists)

        let manageButton = app.buttons["Manage habits"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 3))
        manageButton.tap()

        XCTAssertTrue(app.staticTexts["Archived"].waitForExistence(timeout: 3))
        let archivedReading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(archivedReading.waitForExistence(timeout: 3))
        archivedReading.tap()

        let archivedMoreButton = app.buttons["More habit actions"]
        XCTAssertTrue(archivedMoreButton.waitForExistence(timeout: 3))
        archivedMoreButton.tap()

        let restoreButton = app.buttons["Restore from archive"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 3))
        restoreButton.tap()

        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3))

        let restoredMoreButton = app.buttons["More habit actions"]
        XCTAssertTrue(restoredMoreButton.waitForExistence(timeout: 3))
        restoredMoreButton.tap()
        XCTAssertTrue(
            app.buttons["Pause habit"].waitForExistence(timeout: 3)
        )
    }

    private func launchSeededDemo() {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--seed-watch-sync-demo",
            "--disable-cloud-sync"
        ]
        app.launch()
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

        let everyDayButton = app.buttons["Every day"]
        let weekdaysButton = app.buttons["Weekdays"]
        XCTAssertTrue(everyDayButton.waitForExistence(timeout: 3))
        XCTAssertTrue(weekdaysButton.waitForExistence(timeout: 3))
        XCTAssertTrue(everyDayButton.isHittable)
        XCTAssertTrue(weekdaysButton.isHittable)

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
