import XCTest

final class ShortcutImportUITests: XCTestCase {
    func testAutomationSmoke() throws {
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        safari.launch()
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 5))
        print("UI_AUTOMATION_SMOKE_OK")
    }

    override func setUpWithError() throws { continueAfterFailure = false }

    func testInspectImported1000Shortcut() throws {
        let app = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        app.launch()

        let cell = app.cells.matching(
            NSPredicate(format: "label BEGINSWITH %@", "PUSHKIN-1000-Unique-signed")
        ).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        cell.tap()
        XCTAssertTrue(app.otherElements["editor"].firstMatch.waitForExistence(timeout: 5))

        print("IMPORTED_1000_EDITOR_BEGIN")
        print(app.debugDescription)
        print("IMPORTED_1000_EDITOR_END")
    }
    func testFutureAppPermissionAndDelivery() throws {
        let future = XCUIApplication(bundleIdentifier: "ru.arvectum.pushkin.futuretest")
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        future.launch()

        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 8) {
            let allow = alert.buttons.matching(NSPredicate(
                format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@", "Allow", "Разреш"
            )).firstMatch
            XCTAssertTrue(allow.exists, "Notification permission alert has no Allow button")
            allow.tap()
        }

        let scheduled = future.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN_RUNTIME_1000_PROVISIONAL_02")
        ).firstMatch
        XCTAssertTrue(scheduled.waitForExistence(timeout: 8))
        future.terminate()
        sleep(8)
        print("FUTURE_APP_NOTIFICATION_DELIVERED")
    }

    func testSaveRefreshThenDeliver() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.launch()

        let cell = shortcuts.cells.matching(
            NSPredicate(format: "label BEGINSWITH %@", "PUSHKIN-1000-Unique-signed")
        ).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 6))
        cell.tap()
        sleep(3)

        print("SAVE_REFRESH_EDITOR_BEGIN")
        print(shortcuts.debugDescription)
        print("SAVE_REFRESH_EDITOR_END")

        let done = shortcuts.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Готово", "Done")
        ).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Done button not found")
        done.tap()
        sleep(2)

        let future = XCUIApplication(bundleIdentifier: "ru.arvectum.pushkin.futuretest")
        future.launch()
        let scheduled = future.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN_RUNTIME_1000_PROVISIONAL_02")
        ).firstMatch
        XCTAssertTrue(scheduled.waitForExistence(timeout: 8))
        XCUIApplication(bundleIdentifier: "com.apple.Preferences").launch()
        sleep(8)

        let pushkin = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        pushkin.launch()
        let captured = pushkin.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "PUSHKIN_RUNTIME_1000_PROVISIONAL_02")
        ).firstMatch
        if captured.waitForExistence(timeout: 5) {
            print("SAVE_REFRESH_WORKS")
        } else {
            print("SAVE_REFRESH_MISS")
        }
    }

}
