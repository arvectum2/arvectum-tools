import XCTest

final class OnboardingUITests: XCTestCase {
    private func app(reset: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "--ui-testing", "--disable-cloud-sync", "--test-onboarding"
        ] + (reset ? ["--reset-onboarding"] : [])
        return app
    }

    func testFirstLaunchCarouselCompletesAndDoesNotReturn() {
        let application = app()
        application.launch()
        let next = application.buttons["chickmark.onboarding.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 12))
        XCTAssertTrue(application.staticTexts["One small habit"].exists)
        next.tap()
        XCTAssertTrue(application.staticTexts["Mark it done"].waitForExistence(timeout: 6))
        next.tap()
        XCTAssertTrue(application.staticTexts["Stay on track"].waitForExistence(timeout: 6))
        application.buttons["chickmark.onboarding.start"].tap()
        XCTAssertTrue(application.buttons["Add"].waitForExistence(timeout: 8))
        application.terminate()
        let secondLaunch = app(reset: false)
        secondLaunch.launch()
        XCTAssertTrue(secondLaunch.buttons["Add"].waitForExistence(timeout: 8))
        XCTAssertFalse(secondLaunch.buttons["chickmark.onboarding.next"].exists)
    }

    func testFirstLaunchSkipDoesNotCreateDataOrAskForPermission() {
        let application = app()
        application.launch()
        XCTAssertTrue(application.buttons["chickmark.onboarding.skip"].waitForExistence(timeout: 12))
        application.buttons["chickmark.onboarding.skip"].tap()
        XCTAssertTrue(application.staticTexts["Start with one habit"].waitForExistence(timeout: 8))
        XCTAssertFalse(application.buttons["chickmark.onboarding.next"].exists)
    }
}
