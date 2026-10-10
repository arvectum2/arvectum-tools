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
            "Habit name"
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
        app.navigationBars[reading].buttons[today].tap()
        let manageButton = app.buttons[manage]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 4))
        manageButton.tap()
        XCTAssertTrue(app.navigationBars[manageTitle ?? manage].waitForExistence(timeout: 4))
        captureStoreScreenshot("\(language)_03_manage")
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

        XCTAssertTrue(
            app.buttons["manage.privacy"].waitForExistence(timeout: 3)
        )
        XCTAssertTrue(
            app.buttons["manage.support"].waitForExistence(timeout: 3)
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
                "Add habit",
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
