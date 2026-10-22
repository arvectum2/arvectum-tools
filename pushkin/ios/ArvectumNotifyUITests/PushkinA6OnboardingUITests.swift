import XCTest

final class PushkinA6OnboardingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// NavigationStack's List only materializes visible rows on iOS 27.
    /// Do not assume a link further down is already in the accessibility tree.
    private func reveal(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        let element = app.descendants(matching: .any)
            .matching(identifier: identifier).firstMatch
        for _ in 0..<12 {
            if element.exists && element.isHittable { return element }
            app.swipeUp()
        }
        for _ in 0..<12 {
            if element.exists && element.isHittable { return element }
            app.swipeDown()
        }
        return element
    }

    func testSetupExplainsActivationAndCaptureProofWithoutClaimingFullCoverage() {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launch()
        app.tabBars.buttons["Apps"].tap()

        XCTAssertTrue(reveal("setup-base-automation", in: app).exists)
        XCTAssertTrue(reveal("open-setup-automations", in: app).exists)
        XCTAssertTrue(reveal("setup-optional-groups", in: app).exists)

        // Only proves the app owns the guidance. It does not touch Shortcuts.
        XCTAssertTrue(app.tabBars.buttons["Apps"].exists)
    }

    func testOptionalGroupPlannerCanAddAndClearWithoutEditingHistory() {
        let app = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.notify")
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "--store-tab", "1"
        ]
        app.launch()
        app.tabBars.buttons["Apps"].tap()
        let plan = reveal("setup-optional-groups", in: app)
        XCTAssertTrue(plan.exists && plan.isHittable)
        plan.tap()

        let search = reveal("group-app-search", in: app)
        XCTAssertTrue(search.exists)
        let clear = app.descendants(matching: .any)
            .matching(identifier: "clear-group-plan").firstMatch
        if clear.exists {
            let button = reveal("clear-group-plan", in: app)
            if button.isHittable { button.tap() }
        }

        search.tap()
        // D4.3 search has an explicit Done action. Dismiss keyboard before
        // locating the group generated below the chooser.
        search.typeText("Telegram\n")
        let telegram = reveal("group-select-ph.telegra.Telegraph", in: app)
        XCTAssertTrue(telegram.exists && telegram.isHittable)
        telegram.tap()

        let group = reveal("optional-group-1", in: app)
        XCTAssertTrue(group.exists)
        let clearPlan = reveal("clear-group-plan", in: app)
        XCTAssertTrue(clearPlan.exists)
        clearPlan.tap()
        XCTAssertFalse(app.descendants(matching: .any)
            .matching(identifier: "optional-group-1").firstMatch.exists)
    }
}
