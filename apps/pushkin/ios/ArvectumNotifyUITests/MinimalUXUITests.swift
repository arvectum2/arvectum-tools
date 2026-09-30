import XCTest

final class MinimalUXUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingOpensShortcutPreviewDirectly() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let setup = app.buttons["setup-pushkin"].firstMatch
        XCTAssertTrue(setup.waitForExistence(timeout: 6))
        setup.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 8))

        let add = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        ).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8))
        print("MINIMAL_ONBOARDING_DIRECT_PREVIEW_OK")
    }

    func testAddAppOpensMicroPackageDirectly() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let addApp = app.buttons["add-app"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 6))
        addApp.tap()

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        search.tap()
        search.typeText("Telegram")

        let telegram = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Telegram")
        ).firstMatch
        XCTAssertTrue(telegram.waitForExistence(timeout: 6))
        telegram.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 8))

        let add = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        ).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8))
        print("MINIMAL_ADD_APP_DIRECT_PREVIEW_OK")
    }

    func testTeamlessCapCutCanBeAdded() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let addApp = app.buttons["add-app"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 6))
        addApp.tap()

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        search.tap()
        search.typeText("CapCut")

        let capCut = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "CapCut")
        ).firstMatch
        XCTAssertTrue(capCut.waitForExistence(timeout: 6))
        capCut.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 8))

        let add = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        ).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add Shortcut did not appear")
        if add.isHittable {
            add.tap()
        } else {
            // Shortcuts' import preview can visually expose the button while
            // XCTest reports it non-hittable. Tap its visible bottom control.
            shortcuts.coordinate(
                withNormalizedOffset: CGVector(dx: 0.5, dy: 0.94)
            ).tap()
        }
        sleep(5)

        let remainingAdds = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        )
        let anyHittable = (0..<remainingAdds.count).contains {
            let element = remainingAdds.element(boundBy: $0)
            return element.exists && element.isHittable
        }
        XCTAssertFalse(anyHittable, "Top import preview did not dismiss after Add")
        print("TEAMLESS_CAPCUT_ADD_DONE")
        print(shortcuts.debugDescription)
    }

    func testFutureTeamlessMicroPackageOpensOnPhysicalDevice() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let addApp = app.buttons["add-app"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 6))
        addApp.tap()

        let future = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN Future Test")
        ).firstMatch
        XCTAssertTrue(future.waitForExistence(timeout: 6))
        let previewStart = Date()
        future.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 8))

        let add = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        ).firstMatch
        XCTAssertTrue(
            add.waitForExistence(timeout: 8),
            "Teamless Future Test package did not reach Shortcuts import preview"
        )
        let previewLatency = Date().timeIntervalSince(previewStart)
        print("FUTURE_MICRO_PREVIEW_LATENCY_SECONDS=\(previewLatency)")
        print("FUTURE_TEAMLESS_IMPORT_PREVIEW_OK")
        print(shortcuts.debugDescription)
    }

    func testDismissVerifiedCoverageCard() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let done = app.buttons["Done"].firstMatch
        XCTAssertTrue(
            done.waitForExistence(timeout: 6),
            "Verified coverage Done button missing"
        )
        done.tap()

        let verified = app.staticTexts["Coverage verified"].firstMatch
        XCTAssertFalse(
            verified.waitForExistence(timeout: 2),
            "Coverage finish card did not clear after Done"
        )
        print("COVERAGE_FINISH_CARD_DISMISSED")
    }

    func testContinueFutureTeamlessPhysicalProof() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6))

        let add = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        ).firstMatch
        if add.waitForExistence(timeout: 2) {
            add.tap()
            sleep(3)
        }

        let replaceAlert = shortcuts.alerts.firstMatch
        if replaceAlert.exists {
            let replace = replaceAlert.buttons.matching(
                NSPredicate(
                    format: "label == %@ OR label == %@ OR label CONTAINS[c] %@",
                    "Replace", "Заменить", "replace"
                )
            ).firstMatch
            if replace.exists { replace.tap(); sleep(3) }
        }

        let back = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@",
                "Back", "Назад"
            )
        ).firstMatch
        if back.waitForExistence(timeout: 6) {
            back.tap()
            sleep(2)
        }

        let automationTitle = shortcuts.staticTexts.matching(
            NSPredicate(
                format: "label == %@ OR label == %@",
                "Automation", "Автоматизация"
            )
        ).firstMatch

        if !automationTitle.exists {
            let library = shortcuts.buttons.matching(
                NSPredicate(
                    format: "label == %@ OR label == %@",
                    "Library", "Медиатека"
                )
            ).firstMatch
            if library.exists {
                library.tap()
                sleep(1)
            }

            let automationTab = shortcuts.buttons.matching(
                NSPredicate(
                    format: "label == %@ OR label == %@",
                    "Automation", "Автоматизация"
                )
            ).firstMatch
            XCTAssertTrue(
                automationTab.waitForExistence(timeout: 6),
                "Automation entry missing after micro import"
            )
            automationTab.tap()
            sleep(2)
        }

        let target = shortcuts.switches.matching(
            NSPredicate(
                format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@",
                "PUSHKIN Future Test", "PUSHKIN"
            )
        ).firstMatch
        if !target.waitForExistence(timeout: 2) {
            for _ in 0..<3 {
                shortcuts.swipeUp()
                sleep(1)
                if target.exists { break }
            }
        }
        XCTAssertTrue(
            target.exists,
            "Future Test micro automation missing"
        )

        let initial = String(describing: target.value ?? "")
        print("FUTURE_MICRO_TOGGLE_INITIAL=\(initial)")
        if initial == "0" {
            target.coordinate(
                withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)
            ).tap()
            sleep(2)
        }
        print("FUTURE_MICRO_TOGGLE_FINAL=\(target.value ?? "nil")")

        let future = XCUIApplication(bundleIdentifier: "ru.arvectum.pushkin.futuretest")
        future.launch()
        let marker = future.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN_RUNTIME_1000_PROVISIONAL_02")
        ).firstMatch
        XCTAssertTrue(marker.waitForExistence(timeout: 8))
        future.terminate()
        sleep(8)

        let pushkin = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        pushkin.launch()
        let captured = pushkin.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN_RUNTIME_1000_PROVISIONAL_02")
        ).firstMatch
        XCTAssertTrue(
            captured.waitForExistence(timeout: 8),
            "PUSHKIN did not capture Future Test notification after micro import"
        )
        print("FUTURE_TEAMLESS_PHYSICAL_PROOF_OK")
    }
}
