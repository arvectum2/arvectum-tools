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
