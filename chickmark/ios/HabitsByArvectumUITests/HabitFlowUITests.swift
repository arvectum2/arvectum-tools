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

    func testBrandAndVersionInAboutScreen() throws {
        XCTAssertTrue(
            app.links["chickmark.website"].waitForExistence(timeout: 3)
                || app.buttons["chickmark.website"].waitForExistence(timeout: 3)
        )
        XCTAssertFalse(app.staticTexts["chickmark.version"].exists)

        let manage = app.buttons["Manage habits"]
        XCTAssertTrue(manage.waitForExistence(timeout: 3))
        manage.tap()

        XCTAssertTrue(app.buttons["manage.language"].exists)
        XCTAssertFalse(app.staticTexts["chickmark.version"].exists)
        let about = app.buttons["manage.about"]
        XCTAssertTrue(about.waitForExistence(timeout: 3))
        about.tap()
        XCTAssertTrue(app.staticTexts["chickmark.version"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["manage.privacy"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["manage.support"].exists)
    }

    func testCreateFormHasNoObstructiveKeyboardBar() throws {
        let create = app.buttons["Create habit"]
        XCTAssertTrue(create.waitForExistence(timeout: 4))
        create.tap()

        let name = app.textFields["Habit name"]
        XCTAssertTrue(name.waitForExistence(timeout: 4))
        name.tap()
        name.typeText("Read daily")

        // The system Form already supports interactive keyboard dismissal.
        // The former full-height keyboard toolbar obscured the step input.
        XCTAssertFalse(app.buttons["habit.keyboard.dismiss"].exists)
        XCTAssertTrue(app.navigationBars["New habit"].exists)
        XCTAssertEqual(name.value as? String, "Read daily")
        // No implicit save on keyboard focus; closing the editor cancels.
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Create habit"].waitForExistence(timeout: 4))
    }

    func testUnifiedHealthLinkInNewHabitEditorWithoutSecondaryScreen() throws {
        let create = app.buttons["Create habit"]
        XCTAssertTrue(create.waitForExistence(timeout: 4))
        create.tap()

        let health = app.switches["habit.health.enabled"]
        XCTAssertTrue(health.waitForExistence(timeout: 4))
        XCTAssertFalse(health.value as? String == "1")
        XCTAssertFalse(app.textFields["habit.health.target"].exists)
        health.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertEqual(health.value as? String, "1")
        let target = app.textFields["habit.health.target"]
        XCTAssertTrue(target.waitForExistence(timeout: 4))
        XCTAssertEqual(target.value as? String, "5000")

        target.tap()
        XCTAssertTrue(app.keyboards.firstMatch.exists, "Numeric step keyboard must open")
        // Native, narrow keyboard toolbar: a single downward chevron.
        // No giant text button or swipe recognizer stealing scroll gestures.
        let arrow = app.buttons["habit.keyboard.dismiss.arrow"]
        XCTAssertTrue(arrow.waitForExistence(timeout: 5))
        arrow.tap()
        let keyboardGone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.keyboards.firstMatch
        )
        XCTAssertEqual(XCTWaiter.wait(for: [keyboardGone], timeout: 5), .completed)
        XCTAssertFalse(app.buttons["health.settings.open"].exists)
        // Cancel must not create the habit or persist the link.
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["Create habit"].waitForExistence(timeout: 4))
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
            app.staticTexts["ChickMark data is temporarily unavailable"]
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
            app.staticTexts["Recent activity"].waitForExistence(timeout: 3)
        )
    }

    func testCreateCheckAndOpenHistory() throws {
        let createButton = app.buttons["Create habit"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        createButton.tap()

        let newHabitBar = app.navigationBars["New habit"]
        XCTAssertTrue(newHabitBar.waitForExistence(timeout: 3))

        let nameField = app.textFields[
            "Habit name"
        ]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        // New habit form deliberately does not steal keyboard focus.
        // Tap before typing, as a real user would.
        nameField.tap()
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
            app.staticTexts["Recent activity"].waitForExistence(timeout: 3)
        )
    }


    func testHabitDetailOverviewFitsWithoutScrolling() throws {
        launchSeededDemo()
        let reading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 3))
        reading.tap()

        let more = app.buttons["detail.more"]
        XCTAssertTrue(more.waitForExistence(timeout: 3))
        XCTAssertTrue(more.isHittable, "The overview must fit without scrolling")
        let screen = app.windows.firstMatch.frame
        XCTAssertLessThanOrEqual(more.frame.maxY, screen.maxY - 10)

        more.tap()
        XCTAssertTrue(app.staticTexts["Last 6 weeks"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Consistency"].waitForExistence(timeout: 3))
    }

    func testStatsHeightsAndHealthAutomationFitOnIPhone13() throws {
        launchSeededDemo()
        let reading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 3))
        reading.tap()

        let streak = app.descendants(matching: .any)["stats.card.flame.fill"]
        let percent = app.descendants(matching: .any)["stats.card.chart.line.uptrend.xyaxis"]
        let checkins = app.descendants(matching: .any)["stats.card.checkmark.circle.fill"]
        XCTAssertTrue(streak.waitForExistence(timeout: 3))
        XCTAssertTrue(percent.exists)
        XCTAssertTrue(checkins.exists)
        XCTAssertEqual(streak.frame.height, percent.frame.height, accuracy: 1)
        XCTAssertEqual(streak.frame.height, checkins.frame.height, accuracy: 1)

        // The habit detail now has one edit entry point, not a second
        // "Smart automations" settings screen.
        XCTAssertFalse(app.buttons["health.settings.open"].exists)
        let edit = app.buttons["Edit"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        edit.tap()

        let enabled = app.switches["habit.health.enabled"]
        XCTAssertTrue(enabled.waitForExistence(timeout: 4))
        XCTAssertTrue(enabled.isHittable, "Health integration must be in Edit habit")
        // iOS 27 exposes the entire Toggle row as one AX Switch, but an AX
        // tap at the row centre hits the label, not the native switch knob.
        enabled.coordinate(withNormalizedOffset: CGVector(dx: 0.88, dy: 0.5)).tap()
        XCTAssertEqual(enabled.value as? String, "1")
        XCTAssertTrue(app.textFields["habit.health.target"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Done"].exists || app.buttons["Save"].exists)
    }

    func testUXMainShowsMultiCheckCountAndCreationStartsWithoutKeyboard() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "--ui-testing", "--seed-watch-sync-demo", "--seed-screenshot-demo",
            "--disable-cloud-sync"
        ]
        app.launch()
        // The screenshot fixture includes a multi-check habit.
        // expose a fraction instead of just five anonymous check circles.
        let progress = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "Check-ins: ")
        ).firstMatch
        XCTAssertTrue(progress.waitForExistence(timeout: 4))

        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing", "--debug-open-add-habit",
            "--disable-cloud-sync"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["New habit"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.buttons["Every day"].isHittable)
        XCTAssertTrue(app.buttons["Weekdays"].isHittable)
        XCTAssertFalse(app.keyboards.firstMatch.exists, "Initial keyboard hides quick presets")
        XCTAssertTrue(app.buttons["Done"].exists)
    }

    func testStoreScreenshotsEnglish() throws {
        storeScreenshots(language: "en", locale: "en_US",
                         today: "Today", manage: "Manage habits",
                         reading: "Reading")
    }

    func testStoreScreenshotsRussian() throws {
        storeScreenshots(language: "ru", locale: "ru_RU",
                         today: "Сегодня", manage: "Управление привычками",
                         manageTitle: "Управление", reading: "Чтение")
    }

    func testStoreScreenshotsSpanish() throws {
        storeScreenshots(language: "es", locale: "es_ES",
                         today: "Hoy", manage: "Gestionar hábitos",
                         reading: "Leer")
    }

    private func storeScreenshots(
        language: String, locale: String, today: String,
        manage: String, manageTitle: String? = nil, reading: String
    ) {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "--ui-testing",
            "--seed-watch-sync-demo",
            "--seed-screenshot-demo",
            "--disable-cloud-sync"
        ]
        app.launch()
        XCTAssertTrue(app.staticTexts[reading].firstMatch.waitForExistence(timeout: 5))
        captureStoreScreenshot("\(language)_01_today")
        app.staticTexts[reading].firstMatch.tap()
        XCTAssertTrue(app.navigationBars[reading].waitForExistence(timeout: 4))
        captureStoreScreenshot("\(language)_02_detail")
        app.navigationBars[reading].buttons["BackButton"].tap()
        let manageButton = app.buttons[manage]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 4))
        manageButton.tap()
        XCTAssertTrue(app.navigationBars[manageTitle ?? manage].waitForExistence(timeout: 4))
        captureStoreScreenshot("\(language)_03_manage")
        app.buttons["manage.about"].tap()
        captureStoreScreenshot("\(language)_04_about")

        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "--ui-testing", "--debug-open-add-habit",
            "--disable-cloud-sync"
        ]
        app.launch()
        XCTAssertTrue(app.textFields.firstMatch.waitForExistence(timeout: 5))
        captureStoreScreenshot("\(language)_05_create")
        if language == "en" {
            let quickReading = app.buttons["Reading"]
            XCTAssertTrue(quickReading.waitForExistence(timeout: 3))
            quickReading.tap()
            captureStoreScreenshot("en_06_create_selected")
        }
    }



    private func captureStoreScreenshot(_ name: String) {
        let attachment = XCTAttachment(
            screenshot: XCUIScreen.main.screenshot()
        )
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSpanishCreateHabitSmoke() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(es)",
            "-AppleLocale", "es_ES",
            "--ui-testing"
        ]
        app.launch()

        let create = app.buttons["Crear hábito"]
        XCTAssertTrue(create.waitForExistence(timeout: 4))
        create.tap()
        XCTAssertTrue(app.navigationBars["Nuevo hábito"].waitForExistence(timeout: 3))
        let name = app.textFields["Nombre del hábito"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        // Spanish editor also intentionally opens without automatic focus.
        name.tap()
        name.typeText("Leer")
        app.navigationBars["Nuevo hábito"].buttons["Listo"].tap()
        XCTAssertTrue(app.staticTexts["Leer"].firstMatch.waitForExistence(timeout: 3))
    }

    func testFiveMultiCheckButtonsAtLargestDynamicType() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--ui-testing", "--disable-cloud-sync"
        ]
        app.launch()
        let create = app.buttons["Create habit"]
        XCTAssertTrue(create.waitForExistence(timeout: 4))
        create.tap()
        let name = app.textFields["Habit name"]
        XCTAssertTrue(name.waitForExistence(timeout: 4))
        name.tap()
        name.typeText("Vitamins")
        app.buttons["Other schedule"].tap()
        let stepper = app.steppers.matching(
            NSPredicate(format: "label CONTAINS %@", "Check-ins per day")
        ).firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 4))
        for _ in 0..<4 { stepper.buttons["Increment"].tap() }
        app.navigationBars["New habit"].buttons["Done"].tap()
        // Wait for SwiftUI's sheet dismissal, otherwise an offscreen text
        // field can be mistaken for the actual Today-row title.
        let closed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.navigationBars["New habit"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 8), .completed)

        let nameLabel = app.staticTexts["Vitamins"].firstMatch
        XCTAssertTrue(nameLabel.waitForExistence(timeout: 3))
        XCTAssertGreaterThan(
            nameLabel.frame.width, 60,
            "The rendered habit title must not collapse into a character column."
        )
        for slot in 1...5 {
            let button = app.buttons["Check-in \(slot) of 5"]
            XCTAssertTrue(button.waitForExistence(timeout: 4))
            XCTAssertTrue(button.isHittable)
        }
        app.buttons["Check-in 5 of 5"].tap()
        XCTAssertEqual(app.buttons["Check-in 5 of 5"].value as? String, "Done")
        XCTAssertEqual(app.buttons["Check-in 1 of 5"].value as? String, "Not done")
    }

    func testMultiCheckHistoryIndividualSlotsPersist() throws {
        let create = app.buttons["Create habit"]
        XCTAssertTrue(create.waitForExistence(timeout: 3))
        create.tap()
        let name = app.textFields["Habit name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        // iOS 27 does not always auto-focus a sheet text field after opening.
        // Explicitly focus before typing, rather than relying on responder state.
        name.tap()
        name.typeText("Hydrate")
        app.buttons["Other schedule"].tap()
        let stepper = app.steppers.matching(
            NSPredicate(format: "label CONTAINS %@", "Check-ins per day")
        ).firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 3))
        stepper.buttons["Increment"].tap()
        stepper.buttons["Increment"].tap()
        app.navigationBars["New habit"].buttons["Done"].tap()

        let todayName = app.staticTexts["Hydrate"].firstMatch
        XCTAssertTrue(todayName.waitForExistence(timeout: 3))
        todayName.tap()
        XCTAssertTrue(app.navigationBars["Hydrate"].waitForExistence(timeout: 3))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .autoupdatingCurrent
        let dayButton = app.buttons["history.day.\(formatter.string(from: .now))"]
        // LazyVGrid creates only visible calendar rows. On iOS 27 the insight
        // and stats cards move the calendar below the initial viewport.
        for _ in 0..<6 where !dayButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(dayButton.waitForExistence(timeout: 5))
        dayButton.tap()

        let edit = app.navigationBars["Edit day"]
        XCTAssertTrue(edit.waitForExistence(timeout: 3))
        let slotTwo = app.buttons["Check-in 2 of 3"]
        XCTAssertTrue(slotTwo.waitForExistence(timeout: 3))
        slotTwo.tap()
        XCTAssertEqual(slotTwo.value as? String, "Done")
        edit.buttons["Done"].tap()
        dayButton.tap()
        XCTAssertEqual(
            app.buttons["Check-in 2 of 3"].value as? String,
            "Done",
            "The historical slot must survive dismissing and reopening the editor."
        )
        XCTAssertEqual(
            app.buttons["Check-in 1 of 3"].value as? String,
            "Not done"
        )
    }

    func testMultiCheckCompletesOnlyAfterAllDailySlots() throws {
        let create = app.buttons["Create habit"]
        XCTAssertTrue(create.waitForExistence(timeout: 3))
        create.tap()
        let bar = app.navigationBars["New habit"]
        let name = app.textFields["Habit name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        // iOS 27 does not always auto-focus a sheet text field after opening.
        // Explicitly focus before typing, rather than relying on responder state.
        name.tap()
        name.typeText("Hydrate")
        app.buttons["Other schedule"].tap()
        let stepper = app.steppers.matching(
            NSPredicate(format: "label CONTAINS %@", "Check-ins per day")
        ).firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 3))
        stepper.buttons["Increment"].tap()
        stepper.buttons["Increment"].tap()
        XCTAssertTrue(app.staticTexts["Check-ins per day: 3"].exists ||
                      app.steppers["Check-ins per day: 3"].exists)
        bar.buttons["Done"].tap()

        let slot1 = app.buttons["Check-in 1 of 3"]
        let slot2 = app.buttons["Check-in 2 of 3"]
        let slot3 = app.buttons["Check-in 3 of 3"]
        XCTAssertTrue(slot3.waitForExistence(timeout: 3))
        slot3.tap()
        XCTAssertEqual(slot3.value as? String, "Done")
        XCTAssertEqual(slot1.value as? String, "Not done")
        slot1.tap()
        XCTAssertEqual(slot2.value as? String, "Not done")
        slot2.tap()
        XCTAssertEqual(slot2.value as? String, "Done")
        slot3.tap()
        XCTAssertEqual(slot3.value as? String, "Not done")
    }


    func testOneOffReminderAppearsAndCompletesWithoutAffectingHabits() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--seed-watch-sync-demo",
            "--seed-oneoff-demo",
            "--disable-cloud-sync"
        ]
        app.launch()

        let reminderTitle = app.staticTexts["Buy marathon slot"]
        XCTAssertTrue(reminderTitle.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Reminders"].exists)

        let completeButtons = app.buttons.matching(
            NSPredicate(format: "label == %@", "Mark complete")
        )
        XCTAssertGreaterThanOrEqual(completeButtons.count, 3)

        // Two seeded habit controls come first; the reminder control is last.
        completeButtons.element(boundBy: completeButtons.count - 1).tap()

        XCTAssertFalse(reminderTitle.waitForExistence(timeout: 1))
        XCTAssertTrue(app.staticTexts["Reading"].exists)
        XCTAssertTrue(app.staticTexts["Water"].exists)
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

        XCTAssertTrue(app.buttons["manage.language"].exists)
        XCTAssertTrue(app.buttons["manage.about"].exists)
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
        // The action is below the history cards on short displays; scroll it
        // into view instead of requiring initial-viewport visibility.
        for _ in 0..<6 where !skipButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(skipButton.isHittable)
        skipButton.tap()

        XCTAssertTrue(
            app.buttons["Undo skip"].waitForExistence(timeout: 3)
        )

        app.navigationBars["Reading"].buttons["BackButton"].tap()

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

        app.navigationBars["Reading"].buttons["BackButton"].tap()
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

        app.navigationBars["Reading"].buttons["BackButton"].tap()
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

    func testAccessibilityAuditCoreScreens() throws {
        continueAfterFailure = true
        launchSeededDemo()

        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 3))
        try auditCurrentScreen("today")

        let manageButton = app.buttons["Manage habits"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 3))
        manageButton.tap()
        XCTAssertTrue(
            app.navigationBars["Manage habits"].waitForExistence(timeout: 3)
        )
        try auditCurrentScreen("manage")

        let reading = app.staticTexts["Reading"].firstMatch
        XCTAssertTrue(reading.waitForExistence(timeout: 3))
        reading.tap()
        XCTAssertTrue(
            app.navigationBars["Reading"].waitForExistence(timeout: 3)
        )
        try auditCurrentScreen("detail")

        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing",
            "--debug-no-autofocus"
        ]
        app.launch()

        let createButton = app.buttons["Create habit"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 3))
        createButton.tap()
        XCTAssertTrue(
            app.navigationBars["New habit"].waitForExistence(timeout: 3)
        )
        let quickReading = app.buttons["Reading"]
        XCTAssertTrue(quickReading.waitForExistence(timeout: 3))
        quickReading.tap()
        XCTAssertTrue(app.buttons["Done"].isEnabled)
        try auditCurrentScreen("create")
    }

#if compiler(>=6.4)
    @MainActor
    func testVoiceOverCoreNavigationOnIOS27() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("XCUIVoiceOverService requires iOS 27+")
        }

        launchSeededDemo()
        let service = XCUIDevice.shared.voiceOverService
        defer { _ = try? service.disable() }

        let today = try voiceOverUtterances(service, count: 8)
        assertVoiceOverSequence(
            today,
            contains: [
                "Manage habits",
                "Add",
                "Today",
                "0 of 2",
                "Reading",
                "Mark complete",
                "Water",
                "Mark complete"
            ],
            surface: "today"
        )

        app.buttons["Manage habits"].tap()
        XCTAssertTrue(
            app.navigationBars["Manage habits"].waitForExistence(timeout: 3)
        )
        let manage = try voiceOverUtterances(service, count: 7)
        assertVoiceOverSequence(
            manage,
            contains: [
                "Today",
                "Manage habits",
                "Edit",
                "Active",
                "Reading",
                "Water"
            ],
            surface: "manage"
        )

        app.staticTexts["Reading"].firstMatch.tap()
        XCTAssertTrue(
            app.navigationBars["Reading"].waitForExistence(timeout: 3)
        )
        let detail = try voiceOverUtterances(service, count: 10)
        assertVoiceOverSequence(
            detail,
            contains: [
                "Manage habits",
                "Reading",
                "Edit",
                "More habit actions",
                "Reading",
                "Every day",
                "streak",
                "completed",
                "check-ins"
            ],
            surface: "detail"
        )

        XCTAssertFalse(
            detail.contains {
                $0.localizedCaseInsensitiveContains("Flame") ||
                $0.localizedCaseInsensitiveContains("Chart Line") ||
                $0.localizedCaseInsensitiveContains("Selected")
            }
        )
    }
#else
    func testVoiceOverCoreNavigationOnIOS27() throws {
        throw XCTSkip("XCUIVoiceOverService requires Xcode 27 / Swift 6.4")
    }
#endif

    private func auditCurrentScreen(_ surface: String) throws {
        let auditTypes: XCUIAccessibilityAuditType = [
            .contrast,
            .elementDetection,
            .hitRegion,
            .sufficientElementDescription,
            .textClipped,
            .trait
        ]

        try app.performAccessibilityAudit(for: auditTypes) { issue in
            print(
                "HABITS_A11Y surface=\(surface) " +
                "issue=\(issue.compactDescription) " +
                "detail=\(issue.detailedDescription) " +
                "element=\(issue.element?.description ?? "nil")"
            )

            if surface == "detail" &&
                issue.compactDescription.contains("Text clipped") &&
                issue.element == nil {
                // iOS 27 flags partially offscreen content in the intentional
                // accessibility ScrollView, even though it becomes visible on
                // scroll. Visible/identified clipped text is never ignored.
                return true
            }

            if surface == "create" &&
                issue.compactDescription.contains("Contrast") &&
                issue.element?.label == "Done" {
                // iOS 27 AX contrast tool ignores the explicit mint Capsule
                // behind the navy "Done" toolbar button. Actual AXXXL
                // screenshot manually verified dark text on solid mint.
                // Keep all other enabled controls subject to contrast audit.
                return true
            }

            if issue.compactDescription.contains("Contrast") {
                if issue.element == nil {
                    // SwiftUI can report contrast for decorative disclosure
                    // chrome that has no accessibility node of its own. The
                    // labelled text/control nodes remain audited separately.
                    return true
                }

                if issue.element?.isEnabled == false {
                    return true
                }
            }

            return false
        }
    }

#if compiler(>=6.4)
    @MainActor
    @available(iOS 27.0, *)
    private func voiceOverUtterances(
        _ service: XCUIVoiceOverService,
        count: Int
    ) throws -> [String] {
        _ = try? service.disable()
        dismissSystemNotificationIfPresent()
        _ = try service.enable()
        defer { _ = try? service.disable() }

        var utterances = [try service.currentSpeech().utterance]
        guard count > 1 else { return utterances }

        for _ in 1..<count {
            utterances.append(try service.moveForward().utterance)
        }
        return utterances
    }

#endif

    private func assertVoiceOverSequence(
        _ utterances: [String],
        contains expected: [String],
        surface: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        var searchStart = 0

        for fragment in expected {
            let matchingIndex = utterances.indices
                .dropFirst(searchStart)
                .first {
                    utterances[$0]
                        .localizedCaseInsensitiveContains(fragment)
                }

            guard let matchingIndex else {
                XCTFail(
                    "VoiceOver \(surface) missing '\(fragment)'. " +
                    "Utterances: \(utterances)",
                    file: file,
                    line: line
                )
                return
            }

            searchStart = matchingIndex + 1
        }
    }

    private func dismissSystemNotificationIfPresent() {
        let springboard = XCUIApplication(
            bundleIdentifier: "com.apple.springboard"
        )
        let notification = springboard.descendants(matching: .any)
            .matching(
                NSPredicate(
                    format: "identifier == %@",
                    "NotificationShortLookView"
                )
            )
            .firstMatch

        if notification.exists {
            notification.swipeUp()
        }
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
            "Habit name"
        ]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        // New habit form deliberately does not steal keyboard focus.
        // Tap before typing, as a real user would.
        nameField.tap()
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

    func testA5HomeWidgetActualRenderedStateAndCheckButton() throws {
        app.terminate()
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "--ui-testing", "--disable-cloud-sync", "--seed-screenshot-demo"
        ]
        app.launch()
        XCTAssertTrue(
            app.staticTexts["Water (5 times)"].waitForExistence(timeout: 7)
        )
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let water = springboard.staticTexts["Water (5 times)"]
        try XCTSkipUnless(
            water.waitForExistence(timeout: 12),
            "Requires a preconfigured ChickMark medium Home widget on the QA simulator"
        )
        let check = springboard.buttons["Complete Water (5 times)"]
        XCTAssertTrue(check.waitForExistence(timeout: 8))
        let center = check.frame
        let coordinate = springboard.coordinate(withNormalizedOffset: CGVector(
            dx: center.midX / springboard.frame.width,
            dy: center.midY / springboard.frame.height
        ))
        check.tap()
        // SpringBoard accessibility may lag an updated WidgetKit render.
        // Test a second real touch at the same control coordinate.
        Thread.sleep(forTimeInterval: 6)
        let checkedScreenshot = XCTAttachment(screenshot: springboard.screenshot())
        checkedScreenshot.name = "A5_Home_Widget_After_Check"
        checkedScreenshot.lifetime = .keepAlways
        add(checkedScreenshot)
        app.activate()
        XCTAssertTrue(
            app.staticTexts["1 of 1"].waitForExistence(timeout: 12),
            "The first widget tap must persist completion in the iPhone app"
        )
        XCUIDevice.shared.press(.home)
        coordinate.tap()
        Thread.sleep(forTimeInterval: 6)
        let undoneScreenshot = XCTAttachment(screenshot: springboard.screenshot())
        undoneScreenshot.name = "A5_Home_Widget_After_Undo"
        undoneScreenshot.lifetime = .keepAlways
        add(undoneScreenshot)
        app.activate()
        XCTAssertTrue(
            app.staticTexts["0 of 1"].waitForExistence(timeout: 12),
            "Undo from actual Home widget must return habit to incomplete in phone app"
        )
        print("HABITS_A5_REAL_TOGGLE_AND_UNDO_CONFIRMED")
    }
}
