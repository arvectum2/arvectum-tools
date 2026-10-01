import XCTest

final class MinimalUXUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testReleaseShellIsConsumerFacing() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        XCTAssertTrue(app.staticTexts["PUSHKIN"].firstMatch.waitForExistence(timeout: 6))
        XCTAssertTrue(app.tabBars.buttons["History"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["Apps"].firstMatch.exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].firstMatch.exists)
        XCTAssertFalse(app.tabBars.buttons["Diagnostics"].firstMatch.exists)

        let settings = app.tabBars.buttons["Settings"].firstMatch
        settings.tap()

        XCTAssertTrue(app.staticTexts["On this iPhone"].firstMatch.waitForExistence(timeout: 6))
        XCTAssertTrue(app.buttons["delete-all-history"].firstMatch.exists)
        XCTAssertTrue(app.links["privacy-policy"].firstMatch.exists)

        print("RELEASE_CONSUMER_SHELL_OK")
    }

    func testPrimaryUtilityTabsFitWithoutScrolling() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let appsTab = app.tabBars.buttons["Apps"].firstMatch
        XCTAssertTrue(appsTab.waitForExistence(timeout: 6))
        appsTab.tap()

        let addApp = app.buttons["add-app-from-apps-tab"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 6))
        XCTAssertTrue(addApp.isHittable)
        XCTAssertFalse(
            app.staticTexts[
                "Local on this iPhone · no account or cloud"
            ].firstMatch.exists,
            "Apps should not repeat privacy copy from Settings"
        )

        let settingsTab = app.tabBars.buttons["Settings"].firstMatch
        settingsTab.tap()

        let deleteHistory = app.buttons["delete-all-history"].firstMatch
        let privacy = app.links["privacy-policy"].firstMatch
        let support = app.links["support-link"].firstMatch

        XCTAssertTrue(deleteHistory.waitForExistence(timeout: 6))
        XCTAssertTrue(deleteHistory.isHittable)
        XCTAssertTrue(privacy.exists)
        XCTAssertTrue(privacy.isHittable)
        XCTAssertTrue(support.exists)
        XCTAssertTrue(support.isHittable)

        print("PRIMARY_TABS_NO_SCROLL_REQUIRED_OK")
    }

    func testAddAppAndManualScreensFitWithoutScrolling() throws {
        let picker = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        picker.launchEnvironment["PUSHKIN_DEBUG_SCREEN"] = "add-app"
        picker.launch()

        let search = picker.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))

        let yandex = picker.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Yandex Go")
        ).firstMatch
        XCTAssertTrue(yandex.waitForExistence(timeout: 6))
        XCTAssertTrue(yandex.isHittable)

        search.tap()
        search.typeText("a")

        let manual = picker.buttons["manual-add-app"].firstMatch
        XCTAssertTrue(manual.waitForExistence(timeout: 6))
        XCTAssertTrue(
            manual.isHittable,
            "Manual fallback must remain visible with the keyboard open"
        )

        picker.terminate()

        let guide = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        guide.launchEnvironment["PUSHKIN_DEBUG_SCREEN"] = "manual-add"
        guide.launch()

        let shortcuts = guide.buttons["Open Shortcuts"].firstMatch
        XCTAssertTrue(shortcuts.waitForExistence(timeout: 6))
        XCTAssertTrue(shortcuts.isHittable)

        print("ADD_APP_AND_MANUAL_NO_SCROLL_REQUIRED_OK")
    }

    func testNoDuplicateShortcutsActionsInCompactFlow() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchEnvironment["PUSHKIN_STORE_SCREENSHOT_FIXTURE"] = "1"
        app.launch()

        let appsTab = app.tabBars.buttons["Apps"].firstMatch
        XCTAssertTrue(appsTab.waitForExistence(timeout: 6))
        appsTab.tap()

        XCTAssertFalse(
            app.buttons.matching(
                NSPredicate(
                    format: "label CONTAINS[c] %@",
                    "Shortcut"
                )
            ).firstMatch.exists,
            "Active Apps screen must not expose a duplicate Shortcuts action"
        )
        XCTAssertFalse(
            app.links.matching(
                NSPredicate(
                    format: "label CONTAINS[c] %@",
                    "automation"
                )
            ).firstMatch.exists,
            "Active Apps screen must not expose a duplicate automation link"
        )

        app.terminate()

        let guide = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        guide.launchEnvironment["PUSHKIN_DEBUG_SCREEN"] = "manual-add"
        guide.launch()

        let shortcuts = guide.buttons.matching(
            NSPredicate(format: "label == %@", "Open Shortcuts")
        )
        XCTAssertTrue(shortcuts.firstMatch.waitForExistence(timeout: 6))
        XCTAssertEqual(
            shortcuts.count,
            1,
            "Manual setup should expose exactly one Shortcuts destination"
        )
        print("NO_DUPLICATE_SHORTCUTS_ACTIONS_OK")
    }

    func testFutureNativeAdSlotHasReservedFeedPosition() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchEnvironment["PUSHKIN_STORE_SCREENSHOT_FIXTURE"] = "1"
        app.launchEnvironment["PUSHKIN_PREVIEW_AD_SLOT"] = "1"
        app.launch()

        let slot = app.descendants(matching: .any)
            .matching(identifier: "future-native-ad-slot")
            .firstMatch
        XCTAssertTrue(slot.waitForExistence(timeout: 6))
        XCTAssertTrue(slot.isHittable || slot.frame.height > 0)

        let telegram = app.staticTexts["Telegram"].firstMatch
        let mail = app.staticTexts["Mail"].firstMatch
        let whatsapp = app.staticTexts["WhatsApp Messenger"].firstMatch

        XCTAssertTrue(telegram.exists)
        XCTAssertTrue(mail.exists)
        XCTAssertTrue(whatsapp.exists)
        XCTAssertGreaterThan(
            slot.frame.minY,
            mail.frame.minY,
            "Ad slot should appear after the third notification"
        )
        XCTAssertLessThan(
            slot.frame.minY,
            whatsapp.frame.minY,
            "Ad slot should appear before the fourth notification"
        )
        print("FUTURE_NATIVE_AD_SLOT_OK")
    }

    func testHistorySearchKeyboardCanBeDismissed() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchEnvironment["PUSHKIN_STORE_SCREENSHOT_FIXTURE"] = "1"
        app.launch()

        let search = app.textFields["Search notifications"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 6))
        search.tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 4))

        let dismiss = app.buttons["dismiss-search-keyboard"].firstMatch
        XCTAssertTrue(dismiss.waitForExistence(timeout: 4))
        dismiss.tap()

        XCTAssertFalse(
            app.keyboards.firstMatch.waitForExistence(timeout: 2),
            "Keyboard should dismiss from the visible search control"
        )
        print("HISTORY_SEARCH_KEYBOARD_DISMISS_OK")
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

        let done = app.buttons["app-search-done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 6))
        done.tap()

        let manual = app.buttons["manual-add-app"].firstMatch
        XCTAssertTrue(manual.waitForExistence(timeout: 6))
        manual.tap()

        let openAutomations = app.buttons["Open Shortcuts"].firstMatch
        XCTAssertTrue(openAutomations.waitForExistence(timeout: 6))
        XCTAssertTrue(openAutomations.isHittable)
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

}
