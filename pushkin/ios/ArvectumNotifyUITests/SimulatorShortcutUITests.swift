import XCTest

final class SimulatorShortcutUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDismissShortcutsOnboarding() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let continueButton = shortcuts.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Continue", "Продолжить")
        ).firstMatch
        if continueButton.waitForExistence(timeout: 3) {
            continueButton.tap()
        }
        sleep(1)
        print("SHORTCUTS_READY")
        print(shortcuts.debugDescription)
    }
    func testHandleSafariDownload() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.activate()

        for label in ["Continue", "Продолжить", "Not Now", "Не сейчас"] {
            let b = safari.buttons[label].firstMatch
            if b.waitForExistence(timeout: 1) { b.tap(); sleep(1) }
        }

        let close = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR identifier CONTAINS[c] %@",
            "Close", "Закрыть", "Close"
        )).firstMatch
        if close.waitForExistence(timeout: 1) && close.isHittable { close.tap() }

        let download = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Download", "Загрузить"
        )).firstMatch
        if download.waitForExistence(timeout: 3) {
            download.tap()
            sleep(2)
        }

        print("SAFARI_SIM_DOWNLOAD_BEGIN")
        print(safari.debugDescription)
        print("SAFARI_SIM_DOWNLOAD_END")
    }

    func testTapDownloadOnly() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.activate()
        let download = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Download", "Загрузить"
        )).firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 5))
        download.tap()
        sleep(3)
        print("AFTER_DOWNLOAD_ONLY_BEGIN")
        print(safari.debugDescription)
        print("AFTER_DOWNLOAD_ONLY_END")
    }

    func testImportTeamlessMessagesFromFiles() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()

        let file = files.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "PUSHKIN-Teamless-Messages"))
            .firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 6), "teamless file missing")
        file.tap()
        sleep(2)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label CONTAINS[c] %@",
            "Add Shortcut", "Добавить", "Add Shortcut"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add Shortcut missing")
        add.tap()
        sleep(4)

        print("TEAMLESS_IMPORT_AFTER_ADD_BEGIN")
        print(shortcuts.debugDescription)
        print("TEAMLESS_IMPORT_AFTER_ADD_END")
    }

    func testAddCurrentShortcut() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()
        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label CONTAINS[c] %@",
            "Add Shortcut", "Добавить", "Add Shortcut"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        sleep(3)
        print("SIM_SHORTCUT_ADDED")
        print(shortcuts.debugDescription)
    }

    func testImportFutureShortcutViaSafari() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.activate()

        let download = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Download", "Загрузить"
        )).firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 20), "Download prompt did not appear")
        download.tap()
        sleep(2)

        var downloads = safari.buttons.matching(
            NSPredicate(format: "identifier == %@", "ShowDownloads")
        ).firstMatch
        if !downloads.waitForExistence(timeout: 2) {
            let menu = safari.buttons.matching(
                NSPredicate(format: "identifier == %@", "MoreMenuButton")
            ).firstMatch
            if menu.exists && menu.isHittable { menu.tap(); sleep(1) }
            downloads = safari.buttons.matching(
                NSPredicate(format: "identifier == %@", "ShowDownloads")
            ).firstMatch
        }
        XCTAssertTrue(downloads.waitForExistence(timeout: 5), "Downloads button not found")
        downloads.tap()
        sleep(1)

        let file = safari.cells.matching(NSPredicate(
            format: "label CONTAINS %@",
            "PUSHKIN-Future-App-Test-signed.shortcut"
        )).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5), "Downloaded shortcut not found")
        file.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 5))

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add button not found")
        add.tap()
        sleep(2)

        let replace = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Replace", "Заменить"
        )).firstMatch
        if replace.waitForExistence(timeout: 3) {
            replace.tap()
            sleep(2)
            print("SIM_IMPORT_REPLACED")
        } else {
            print("SIM_IMPORT_ADDED")
        }

        print("SIM_IMPORT_FINAL_BEGIN")
        print(shortcuts.debugDescription)
        print("SIM_IMPORT_FINAL_END")
    }

    func testTapAddShortcutCoordinate() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()
        sleep(1)
        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Add Shortcut", "Добавить"
        )).firstMatch
        print("ADD exists=\(add.exists) hittable=\(add.isHittable) frame=\(add.frame)")
        shortcuts.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.955)).tap()
        sleep(3)
        print("ADD_COORDINATE_TAPPED")
        print(shortcuts.debugDescription)
    }

    func testTapAddShortcutPreview() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 5))
        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label == %@",
            "Add Shortcut", "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 6), "Add Shortcut button not found")
        add.tap()
        sleep(3)
        print("SIM_ADD_SHORTCUT_DONE")
        print(shortcuts.debugDescription)
    }

    func testReplaceCurrentShortcut() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()
        sleep(1)

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Add Shortcut", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.exists, "Add Shortcut preview is not open")
        shortcuts.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.955)).tap()

        let replace = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Replace", "Заменить"
        )).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 5), "Replace confirmation did not appear")
        XCTAssertTrue(replace.isHittable, "Replace is not hittable")
        replace.tap()
        sleep(2)
        print("SIM_REPLACE_DONE")
    }

    func testInspectFilesApp() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        sleep(2)
        print("FILES_APP_BEGIN")
        print(files.debugDescription)
        print("FILES_APP_END")
    }

    func testOpenOneAppShortcutAndAdd() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        let cell = files.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "PUSHKIN-Rebind-OneApp-signed.shortcut")).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 6), "shortcut file not visible")
        cell.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")
        let add = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@", "Add Shortcut", "Add", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add button missing")
        add.tap()
        sleep(3)
        print("ONEAPP_IMPORT_DONE")
        print(shortcuts.debugDescription)
    }

    func testConfirmReplaceOnly() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()
        let replace = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Replace", "Заменить")).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 5), "Replace alert missing")
        replace.tap()
        sleep(3)
        print("ONEAPP_REPLACE_CONFIRMED")
    }

    func testReimportAndReplaceOneApp() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.activate()

        let download = safari.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Download", "Загрузить")).firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 8), "Download prompt missing")
        download.tap()
        sleep(2)

        var downloads = safari.buttons.matching(NSPredicate(format: "identifier == %@", "ShowDownloads")).firstMatch
        if !downloads.waitForExistence(timeout: 2) {
            let menu = safari.buttons.matching(NSPredicate(format: "identifier == %@", "MoreMenuButton")).firstMatch
            if menu.exists && menu.isHittable { menu.tap(); sleep(1) }
            downloads = safari.buttons.matching(NSPredicate(format: "identifier == %@", "ShowDownloads")).firstMatch
        }
        XCTAssertTrue(downloads.waitForExistence(timeout: 5), "Downloads missing")
        downloads.tap()
        sleep(1)

        let file = safari.cells.matching(NSPredicate(format: "label CONTAINS %@", "PUSHKIN-Rebind-OneApp-signed.shortcut")).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5), "Downloaded shortcut missing")
        file.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6))
        let add = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@", "Add Shortcut", "Add", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add missing")
        add.tap()

        let replace = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Replace", "Заменить")).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 5), "Replace missing")
        replace.tap()
        sleep(3)
        print("ONEAPP_REIMPORT_REPLACE_DONE")
    }

    func testRobustReimportFromFiles() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.activate()
        let cell = files.cells.matching(NSPredicate(format: "label CONTAINS %@", "PUSHKIN-Rebind-OneApp")).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "No downloaded shortcut in Files")
        cell.tap()
        sleep(4)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        print("FILES_STATE=\(files.state.rawValue) SHORTCUTS_STATE=\(shortcuts.state.rawValue)")
        let add = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@", "Add Shortcut", "Add", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 10), "Shortcuts preview/Add did not appear")
        add.tap()

        let replace = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Replace", "Заменить")).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 6), "Replace did not appear")
        replace.tap()
        sleep(4)
        print("ROBUST_REIMPORT_REPLACE_DONE")
    }

    func testReplaceOneAppShortcut() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        let cell = files.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "PUSHKIN-Rebind-OneApp-signed.shortcut")).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 6), "shortcut file not visible")
        cell.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")
        let add = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@", "Add Shortcut", "Add", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add button missing")
        add.tap()

        let replace = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Replace", "Заменить")).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 8), "Replace button missing")
        replace.tap()
        sleep(3)
        print("ONEAPP_REPLACE_DONE")
    }

    func testInspectShortcutsLibraryRoot() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let back = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Library", "Медиатека")).firstMatch
        if back.waitForExistence(timeout: 4) { back.tap(); sleep(2) }
        print("SHORTCUTS_ROOT_BEGIN")
        print(shortcuts.debugDescription)
        print("SHORTCUTS_ROOT_END")
    }

    func testEnableNewestDuplicateAutomation() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let library = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Library", "Медиатека")).firstMatch
        if library.waitForExistence(timeout: 3) { library.tap(); sleep(1) }
        let automation = shortcuts.buttons["Automation"].firstMatch
        XCTAssertTrue(automation.waitForExistence(timeout: 5))
        automation.tap(); sleep(2)
        let rows = shortcuts.switches.matching(NSPredicate(format: "label == %@", "When I get a notification from PUSHKIN Future Test, PUSHKIN-Rebind-OneApp-signed"))
        XCTAssertGreaterThanOrEqual(rows.count, 2)
        let newest = rows.element(boundBy: 1)
        print("NEWEST_BEFORE=\(newest.value ?? "nil")")
        newest.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)).tap()
        sleep(3)
        print("NEWEST_AFTER=\(newest.value ?? "nil")")
    }

    func testInspectAutomationList() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let library = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Library", "Медиатека")).firstMatch
        if library.waitForExistence(timeout: 4) { library.tap(); sleep(1) }
        let automation = shortcuts.buttons["Automation"].firstMatch
        XCTAssertTrue(automation.waitForExistence(timeout: 6), "Automation entry missing")
        automation.tap()
        sleep(2)
        print("AUTOMATION_LIST_BEGIN")
        print(shortcuts.debugDescription)
        print("AUTOMATION_LIST_END")
    }

    func testEnableAfterInstallAutomation() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let library = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Library", "Медиатека")).firstMatch
        if library.waitForExistence(timeout: 4) { library.tap(); sleep(1) }
        let automation = shortcuts.buttons["Automation"].firstMatch
        XCTAssertTrue(automation.waitForExistence(timeout: 5))
        automation.tap()
        sleep(2)

        let card = shortcuts.switches.matching(NSPredicate(format: "label == %@", "When I get a notification from PUSHKIN Future Test, PUSHKIN-AfterInstall-OneApp-signed")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 6), "target automation missing")
        print("TARGET_AUTOMATION_BEFORE=\(card.value ?? "nil") frame=\(card.frame)")
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)).tap()
        sleep(3)
        print("TARGET_AUTOMATION_AFTER=\(card.value ?? "nil")")
    }

    func testInspectCurrentShortcutsScreen() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()
        sleep(1)
        print("CURRENT_SHORTCUTS_SCREEN_BEGIN")
        print(shortcuts.debugDescription)
        print("CURRENT_SHORTCUTS_SCREEN_END")
    }

    func testPushkinRefreshDeepLink() throws {
        let pushkin = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        pushkin.launch()

        let setup = pushkin.tabBars.buttons["Setup"].firstMatch
        XCTAssertTrue(setup.waitForExistence(timeout: 5), "Setup tab missing")
        setup.tap()

        let refresh = pushkin.links["Open Automation to Refresh"].firstMatch
        if !refresh.waitForExistence(timeout: 2) {
            pushkin.swipeUp()
        }
        XCTAssertTrue(refresh.waitForExistence(timeout: 5), "Refresh link missing")
        refresh.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 7), "Shortcuts did not foreground")
        let title = shortcuts.staticTexts["Automation"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "Automation screen did not open")
        print("PUSHKIN_REFRESH_DEEPLINK_OK")
    }

    func testOriginalRebind() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let library = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Library", "Медиатека")).firstMatch
        if library.waitForExistence(timeout: 3) { library.tap(); sleep(1) }
        let automation = shortcuts.buttons["Automation"].firstMatch
        if automation.waitForExistence(timeout: 4) { automation.tap(); sleep(2) }
        let row = shortcuts.switches.matching(NSPredicate(format: "label == %@", "When I get a notification from PUSHKIN Future Test, PUSHKIN-Rebind-OneApp-signed")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "original automation missing")
        print("ORIGINAL_INITIAL=\(row.value ?? "nil")")
        if String(describing: row.value ?? "") != "0" { row.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)).tap(); sleep(2) }
        print("ORIGINAL_OFF=\(row.value ?? "nil")")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)).tap()
        sleep(3)
        print("ORIGINAL_ON=\(row.value ?? "nil")")
    }

    func testToggleAfterInstallAutomationTwice() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()
        let library = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Library", "Медиатека")).firstMatch
        if library.waitForExistence(timeout: 3) { library.tap(); sleep(1) }
        let automation = shortcuts.buttons["Automation"].firstMatch
        if automation.waitForExistence(timeout: 4) { automation.tap(); sleep(2) }

        let row = shortcuts.switches.matching(NSPredicate(format: "label == %@", "When I get a notification from PUSHKIN Future Test, PUSHKIN-AfterInstall-OneApp-signed")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "target automation missing")
        print("REBINDSIM_INITIAL=\(row.value ?? "nil")")
        if String(describing: row.value ?? "") != "0" {
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)).tap()
            sleep(2)
        }
        print("REBINDSIM_OFF=\(row.value ?? "nil")")
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)).tap()
        sleep(3)
        print("REBINDSIM_ON=\(row.value ?? "nil")")
    }

    private func measurePackPreview(_ filename: String, marker: String) throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        let cell = files.cells.matching(NSPredicate(format: "label BEGINSWITH %@", filename)).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 6), "pack file missing")
        let start = Date()
        cell.tap()
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 20), "Shortcuts did not foreground")
        let add = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@", "Add Shortcut", "Add", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 20), "Add button missing")
        print("PACK_PREVIEW_\(marker)=\(Date().timeIntervalSince(start))")
    }

    func testPack10Preview() throws { try measurePackPreview("PUSHKIN-Pack-10-signed.shortcut", marker: "10") }
    func testPack25Preview() throws { try measurePackPreview("PUSHKIN-Pack-25-signed.shortcut", marker: "25") }
    func testPack50Preview() throws { try measurePackPreview("PUSHKIN-Pack-50-signed.shortcut", marker: "50") }

    func testCoverageQuickRefreshUX() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let add = app.buttons["add-app"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let search = app.searchFields["Search app"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Karui")

        let row = app.staticTexts["Karui"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(
            safari.wait(for: .runningForeground, timeout: 8),
            "Selecting an app should immediately open its micro-package"
        )

        print("MIN_UPDATE_FLOW_OK")
        print("MIN_UPDATE_IN_APP_TAPS=2")
        print("MIN_UPDATE_TEXT_ENTRY=1")
    }

    func testBundledMicroPackageOpenInMenu() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let add = app.buttons["add-app"].firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.typeText("Karui")

        let row = app.staticTexts["Karui"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        sleep(2)

        print("DOC_INTERACTION_BEGIN")
        print(app.debugDescription)
        print("DOC_INTERACTION_END")

        let shortcutsDestination = app.cells.matching(
            NSPredicate(
                format: "label == %@",
                "Shortcuts"
            )
        ).firstMatch
        XCTAssertTrue(
            shortcutsDestination.waitForExistence(timeout: 5),
            "Shortcuts destination missing from system Open In menu"
        )
        print("DOC_INTERACTION_SHORTCUTS_VISIBLE")
        shortcutsDestination.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(
            shortcuts.wait(for: .runningForeground, timeout: 8),
            "Shortcuts did not open the bundled micro-package"
        )

        let addShortcut = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        ).firstMatch
        XCTAssertTrue(
            addShortcut.waitForExistence(timeout: 8),
            "Bundled micro-package did not reach Add Shortcut preview"
        )

        print("DOC_INTERACTION_TO_SHORTCUTS_OK")
        print("UPDATE_TAPS_BEFORE_ADD=3")
    }

    func testFreshMicroPackageEndToEndActionCount() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()

        let addApp = app.buttons["add-app"].firstMatch
        XCTAssertTrue(addApp.waitForExistence(timeout: 5))
        addApp.tap() // tap 1

        let search = app.textFields["app-search"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.typeText("Karui")

        let row = app.staticTexts["Karui"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap() // tap 2

        let destination = app.cells["Shortcuts"].firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.tap() // tap 3

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 8))

        let addButtons = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@ OR label == %@",
                "Add Shortcut", "Add", "Добавить"
            )
        )
        XCTAssertTrue(addButtons.firstMatch.waitForExistence(timeout: 8))

        var hittableAdd: XCUIElement?
        for index in 0..<addButtons.count {
            let candidate = addButtons.element(boundBy: index)
            if candidate.exists && candidate.isHittable {
                hittableAdd = candidate
                break
            }
        }

        XCTAssertNotNil(hittableAdd, "No hittable Add Shortcut button")
        hittableAdd!.tap() // tap 4
        sleep(3)

        print("FRESH_MICRO_AFTER_ADD_BEGIN")
        print(shortcuts.debugDescription)
        print("FRESH_MICRO_AFTER_ADD_END")

        let back = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@",
                "Back", "Назад"
            )
        ).firstMatch
        XCTAssertTrue(
            back.waitForExistence(timeout: 5),
            "Back button missing after Add Shortcut"
        )
        back.tap() // tap 5
        sleep(2)

        let automationTab = shortcuts.buttons.matching(
            NSPredicate(
                format: "label == %@ OR label == %@",
                "Automation", "Автоматизация"
            )
        ).firstMatch
        XCTAssertTrue(
            automationTab.waitForExistence(timeout: 5),
            "Automation tab missing after returning from editor"
        )
        automationTab.tap() // tap 6
        sleep(2)

        let target = shortcuts.switches.matching(
            NSPredicate(
                format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@",
                "Karui",
                "PUSHKIN"
            )
        ).firstMatch

        XCTAssertTrue(
            target.waitForExistence(timeout: 8),
            "Fresh micro automation missing after Add Shortcut"
        )

        let initial = String(describing: target.value ?? "")
        print("FRESH_MICRO_TOGGLE_INITIAL=\(initial)")

        if initial == "0" {
            target.coordinate(
                withNormalizedOffset: CGVector(dx: 0.86, dy: 0.49)
            ).tap() // tap 7
            sleep(2)
        }

        print("FRESH_MICRO_TOGGLE_FINAL=\(target.value ?? "nil")")
        print("FRESH_MICRO_TOTAL_TAPS_TO_ENABLED=\(initial == "0" ? 7 : 6)")
    }

    func testTapReplaceInsideAlert() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        let token = addUIInterruptionMonitor(withDescription: "Force Replace") { alert in
            guard alert.buttons["Replace"].exists else { return false }
            alert.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.54)).tap()
            print("CUSTOM_REPLACE_HANDLER_RAN")
            return true
        }
        shortcuts.activate()
        let alert = shortcuts.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Replace alert missing")
        alert.buttons["Replace"].firstMatch.tap()
        sleep(3)
        removeUIInterruptionMonitor(token)
        print("DIRECT_REPLACE_TAPPED")
    }

}
