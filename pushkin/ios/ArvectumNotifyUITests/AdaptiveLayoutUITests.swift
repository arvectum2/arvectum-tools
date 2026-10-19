import XCTest

/// Simulator fixture only; real notification history is never touched.
final class AdaptiveLayoutUITests: XCTestCase {
    /// No external Shortcuts changes. Verify secondary routes and user-critical
    /// actions stay readable/reachable under Accessibility XXXL.
    func testAccessibilityXXXLSetupAndCoverageNavigation() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "1"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Источники"].firstMatch
            .waitForExistence(timeout: 10))

        // At AXXXL the long setup guide is scrollable; repeat users must
        // not scroll through every step to reach app management.
        let quickAdd = app.buttons["setup-quick-add"].firstMatch
        XCTAssertTrue(quickAdd.waitForExistence(timeout: 8))
        XCTAssertTrue(quickAdd.isHittable)
        XCTAssertGreaterThanOrEqual(quickAdd.frame.width, 40)
        quickAdd.tap()

        XCTAssertTrue(app.staticTexts["Офлайн-каталог"].firstMatch
            .waitForExistence(timeout: 8))
        let addToPushkin = app.buttons["Подключить приложение"].firstMatch
        for _ in 0..<5 where !addToPushkin.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(addToPushkin.isHittable)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Pushkin quick coverage navigation AXXXL"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testAccessibilityXXXLSettingsPrivacyAndHistory() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--store-tab", "2"
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Настройки"].firstMatch
            .waitForExistence(timeout: 10))
        let brand = app.descendants(matching: .any)["pushkin-brand-compact"].firstMatch
        XCTAssertTrue(brand.exists)
        XCTAssertLessThanOrEqual(brand.frame.height, 40)
        XCTAssertLessThan(brand.frame.width, 260)

        let privacy = app.descendants(matching: .any)["pushkin.settings.privacy-policy"].firstMatch
        for _ in 0..<12 where !privacy.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(privacy.isHittable, "Privacy policy must be reachable at AXXXL")
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Pushkin settings privacy AXXXL"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        // Tab navigation is already covered in its own test at normal type.
        // Do not invoke destructive actions on a shared QA container.
        let history = app.tabBars.buttons["История"].firstMatch
        XCTAssertTrue(history.exists)
    }

    func testHistoryAndSearchSurviveOrientationChanges() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 14))
        let search = app.textFields["Search notifications"].firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        search.typeText("Delivery")
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.staticTexts["Delivery update"].firstMatch.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    func testSetupRemainsAccessibleAfterRotation() throws {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = ["--store-screenshot-fixture"]
        app.launch()
        let apps = app.descendants(matching: .any)["Apps"].firstMatch
        XCTAssertTrue(apps.waitForExistence(timeout: 8))
        apps.tap()
        XCTAssertTrue(app.staticTexts["Apps & Setup"].firstMatch.waitForExistence(timeout: 8)
                      || app.navigationBars["Apps & Setup"].firstMatch.exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.buttons["Apps"].exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.buttons["History"].exists)
    }
}
