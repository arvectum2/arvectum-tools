import XCTest

final class MinimalUXUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRussianNavigationAndEmptyState() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments += ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["История"].firstMatch
            .waitForExistence(timeout: 8))
        XCTAssertTrue(app.tabBars.buttons["Источники"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["Настройки"].firstMatch.exists)

        let sources = app.tabBars.buttons["Источники"].firstMatch
        sources.tap()
        XCTAssertTrue(app.navigationBars["Источники"].firstMatch
            .waitForExistence(timeout: 8))

        let settings = app.tabBars.buttons["Настройки"].firstMatch
        settings.tap()
        XCTAssertTrue(app.staticTexts["На iPhone"].firstMatch
            .waitForExistence(timeout: 8))
    }

    func testReleaseShellIsConsumerFacing() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        XCTAssertTrue(app.staticTexts["PUSHKIN"].firstMatch.waitForExistence(timeout: 6))
        let brand = app.descendants(matching: .any)["pushkin-brand-compact"].firstMatch
        XCTAssertTrue(brand.exists)
        XCTAssertLessThan(brand.frame.width, 240, "Brand should not crowd the screen")
        XCTAssertLessThanOrEqual(brand.frame.height, 40)

        XCTAssertTrue(app.tabBars.buttons["History"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["Apps"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].firstMatch.exists)
        XCTAssertFalse(app.tabBars.buttons["Diagnostics"].firstMatch.exists)

        let settings = app.tabBars.buttons["Settings"].firstMatch
        settings.tap()

        XCTAssertTrue(app.staticTexts["On this iPhone"].firstMatch.waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["Delete all history"].firstMatch.exists)
        XCTAssertTrue(app.links["Privacy policy"].firstMatch.exists)

        print("RELEASE_CONSUMER_SHELL_OK")
    }

    func testOnboardingShowsFreeTermsBeforeOpeningShortcuts() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let setup = app.buttons["setup-pushkin"].firstMatch
        XCTAssertTrue(setup.waitForExistence(timeout: 6))
        let terms = app.descendants(matching: .any)
            .matching(identifier: "pushkin.free-before-setup").firstMatch
        XCTAssertTrue(terms.exists, "Free terms must be visible before setup")
        setup.tap()

        let detailedTerms = app.descendants(matching: .any)
            .matching(identifier: "pushkin.setup.free-terms").firstMatch
        XCTAssertTrue(detailedTerms.waitForExistence(timeout: 6))
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(identifier: "setup-base-automation").firstMatch.exists)
        // Do not import or enable a real personal Shortcut in a UI smoke test.
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

    func testManualSetupIsDiscoverableBeforeSearching() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()
        app.buttons["add-app"].tap()

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        XCTAssertEqual(search.value as? String, search.placeholderValue,
                       "Search should be empty initially")

        let manual = app.buttons["manual-add-app"].firstMatch
        XCTAssertTrue(manual.waitForExistence(timeout: 6),
                      "Manual setup must not require a failed catalog search")
        manual.tap()
        XCTAssertTrue(app.descendants(matching: .any)
            .matching(identifier: "open-manual-automations").firstMatch
            .waitForExistence(timeout: 6))
        // Opening this guide must not modify Apple's Shortcuts.
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
