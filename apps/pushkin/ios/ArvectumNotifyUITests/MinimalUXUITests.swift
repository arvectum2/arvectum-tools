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
}
