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

    func testAddAppPickerStartsCalmAndProductionOnly() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let addApp = app.buttons["add-app"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 6))
        addApp.tap()

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        XCTAssertEqual(app.keyboards.count, 0, "Picker should not force the keyboard open")
        XCTAssertTrue(app.staticTexts["Popular apps"].firstMatch.exists)

        print("ADD_APP_PICKER_PRODUCTION_UX_OK")
    }

    func testMissingAppOffersOfflineManualPath() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let addApp = app.buttons["add-app"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 6))
        addApp.tap()

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        search.tap()
        search.typeText("Definitely Missing PUSHKIN App")

        let manual = app.buttons["manual-add-app"].firstMatch
        XCTAssertTrue(manual.waitForExistence(timeout: 6))
        manual.tap()

        let openAutomations = app.buttons[
            "open-manual-automations"
        ].firstMatch
        XCTAssertTrue(openAutomations.waitForExistence(timeout: 6))
        XCTAssertTrue(
            app.staticTexts["Source app"].firstMatch.exists
        )
        print("OFFLINE_MANUAL_ADD_GUIDE_OK")
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

}
