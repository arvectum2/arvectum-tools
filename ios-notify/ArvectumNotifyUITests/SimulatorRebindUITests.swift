import XCTest

final class SimulatorRebindUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPhase1ImportOneAppShortcut() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        sleep(1)

        for label in ["Not Now", "Не сейчас"] {
            let b = safari.buttons[label].firstMatch
            if b.exists && b.isHittable { b.tap(); sleep(1) }
        }
        let close = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Close", "Закрыть"
        )).firstMatch
        if close.exists && close.isHittable { close.tap(); sleep(1) }

        let address = safari.textFields.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Address", "Адрес"
        )).firstMatch
        XCTAssertTrue(address.waitForExistence(timeout: 5), "Address field missing")
        address.tap()
        address.typeText("http://192.168.1.80:8765/PUSHKIN-Rebind-OneApp-signed.shortcut\n")

        let download = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Download", "Загрузить"
        )).firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 10), "Download prompt missing")
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
        XCTAssertTrue(downloads.waitForExistence(timeout: 5), "Downloads button missing")
        downloads.tap()
        sleep(1)

        let file = safari.cells.matching(NSPredicate(
            format: "label CONTAINS %@",
            "PUSHKIN-Rebind-OneApp-signed.shortcut"
        )).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 5), "Shortcut file missing in downloads")
        file.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add button missing")
        add.tap()
        sleep(3)

        print("SIM_PHASE1_IMPORT_DONE")
        print(shortcuts.debugDescription)
    }
    func testPhase1bOpenFromFilesAndImport() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        sleep(1)

        let item = files.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN-Rebind")
        ).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 6), "Shortcut not visible in Files")
        item.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add button missing")
        add.tap()
        sleep(3)

        print("SIM_PHASE1B_IMPORT_DONE")
        print(shortcuts.debugDescription)
    }

    func testPhase1cConfirmCurrentImport() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label == %@ OR label == %@",
            "Add Shortcut", "Добавить быструю команду", "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add Shortcut button missing")
        add.tap()
        sleep(3)

        print("SIM_PHASE1C_IMPORT_DONE")
        print(shortcuts.debugDescription)
    }

    func testPhase2ReplaceAfterFutureInstalled() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        sleep(1)

        let item = files.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN-Rebind")
        ).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 6), "Shortcut not visible in Files")
        item.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label == %@ OR label == %@",
            "Add Shortcut", "Добавить быструю команду", "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add Shortcut button missing")
        add.tap()
        sleep(2)

        let replace = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Replace", "Заменить"
        )).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 5), "Replace button missing")
        replace.tap()
        sleep(3)

        print("SIM_PHASE2_REPLACE_DONE")
        print(shortcuts.debugDescription)
    }

    func testPhase3ImportFreshAfterInstall() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        sleep(1)

        let item = files.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN-AfterInstall-OneApp")
        ).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 8), "AfterInstall shortcut not visible in Files")
        item.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")

        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label == %@ OR label == %@",
            "Add Shortcut", "Добавить быструю команду", "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add Shortcut button missing")
        add.tap()
        sleep(3)

        print("SIM_PHASE3_FRESH_IMPORT_DONE")
        print(shortcuts.debugDescription)
    }

    func testDownloadWithIDShortcut() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch(); sleep(1)
        let address = safari.textFields.matching(NSPredicate(format: "label == %@ OR label == %@", "Address", "Адрес")).firstMatch
        XCTAssertTrue(address.waitForExistence(timeout: 5))
        address.tap(); address.typeText("http://192.168.1.80:8765/pushkin-loadtest/PUSHKIN-Rebind-WithID-signed.shortcut\n")
        let download = safari.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Download", "Загрузить")).firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 10))
        download.tap(); sleep(3)
        print("WITHID_DOWNLOAD_DONE")
    }

    func testImportWithIDAndReplace() throws {
        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch(); sleep(1)
        let item = files.cells.matching(NSPredicate(format: "label BEGINSWITH %@", "PUSHKIN-Rebind-WithID-signed.shortcut, shortcut")).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 8))
        item.tap(); sleep(3)
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6))
        let add = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@ OR label == %@ OR label == %@", "Add Shortcut", "Добавить быструю команду", "Add", "Добавить")).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8))
        add.tap(); sleep(2)
        let replace = shortcuts.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Replace", "Заменить")).firstMatch
        XCTAssertTrue(replace.waitForExistence(timeout: 5))
        replace.tap(); sleep(3)
        print("WITHID_IMPORT_REPLACE_DONE")
    }

    func testPhase3aDownloadFreshShortcut() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        sleep(1)

        for label in ["Not Now", "Не сейчас"] {
            let b = safari.buttons[label].firstMatch
            if b.exists && b.isHittable { b.tap(); sleep(1) }
        }
        let close = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Close", "Закрыть"
        )).firstMatch
        if close.exists && close.isHittable { close.tap(); sleep(1) }

        let address = safari.textFields.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Address", "Адрес"
        )).firstMatch
        XCTAssertTrue(address.waitForExistence(timeout: 5), "Address field missing")
        address.tap()
        address.typeText("http://192.168.1.80:8765/PUSHKIN-AfterInstall-OneApp-signed.shortcut\n")

        let download = safari.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Download", "Загрузить"
        )).firstMatch
        XCTAssertTrue(download.waitForExistence(timeout: 10), "Download prompt missing")
        download.tap()
        sleep(3)
        print("SIM_PHASE3A_DOWNLOAD_DONE")
    }

    func testPhase2bReimportAndForceReplace() throws {
        let monitor = addUIInterruptionMonitor(withDescription: "Replace existing shortcut") { alert in
            let replace = alert.buttons["Replace"].firstMatch
            if replace.exists {
                replace.tap()
                return true
            }
            return false
        }

        let files = XCUIApplication(bundleIdentifier: "com.apple.DocumentsApp")
        files.launch()
        let item = files.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN-Rebind-OneApp-signed.shortcut")
        ).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 6), "Shortcut not visible in Files")
        item.tap()
        sleep(3)

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 6), "Shortcuts did not open")
        let add = shortcuts.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@ OR label == %@ OR label == %@",
            "Add Shortcut", "Добавить быструю команду", "Add", "Добавить"
        )).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 8), "Add Shortcut button missing")
        add.tap()
        sleep(1)
        shortcuts.tap()
        sleep(3)
        removeUIInterruptionMonitor(monitor)
        print("SIM_PHASE2B_FORCE_REPLACE_DONE")
    }

}
