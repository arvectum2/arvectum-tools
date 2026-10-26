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

#if compiler(>=6.4)
extension OnboardingUITests {
    @MainActor
    func testFirstLaunchOnboardingVoiceOverSpeech() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("VoiceOver speech needs iOS 27 or later")
        }
        let application = app()
        application.launch()
        XCTAssertTrue(application.staticTexts["One small habit"].waitForExistence(timeout: 12))
        let voiceOver = XCUIDevice.shared.voiceOverService
        defer { _ = try? voiceOver.disable() }
        _ = try? voiceOver.disable()
        _ = try voiceOver.enable()
        var spoken: [String] = [try voiceOver.currentSpeech().utterance]
        for _ in 0..<12 { spoken.append(try voiceOver.moveForward().utterance) }
        print("CHICKMARK_ONBOARDING_VOICEOVER=\(spoken)")
        XCTAssertTrue(spoken.contains {
            $0.localizedCaseInsensitiveContains("One small habit")
        }, "VoiceOver must announce the onboarding title")
        XCTAssertTrue(spoken.contains {
            $0.localizedCaseInsensitiveContains("Skip") ||
            $0.localizedCaseInsensitiveContains("Next")
        }, "Onboarding navigation must be discoverable with VoiceOver")
    }
}
#endif
