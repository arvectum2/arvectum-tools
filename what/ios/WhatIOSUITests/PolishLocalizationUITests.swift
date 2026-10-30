import XCTest

/// Polish iPhone native UI smoke: isolated fixture, no recording or Watch transfer.
final class PolishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testPolishAXXXLHomeControlsWithoutRecording() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL",
            "-what.transcription.locale", "en-US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-spanish-axxxl-home"
        ]
        app.launch()
        let later = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Later", "Позже")
        ).firstMatch
        if later.waitForExistence(timeout: 3) { later.tap() }
        XCTAssertTrue(app.staticTexts["Zapisz tę myśl"].waitForExistence(timeout: 12))
        let primary = app.buttons["what.record.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 12))
        XCTAssertTrue(primary.isHittable)
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.isHittable)
        XCTAssertEqual(text.label, "Nowa notatka tekstowa")
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.isHittable)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.isHittable)
        XCTAssertTrue(library.label.hasPrefix("Wszystkie notatki, "), library.label)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "uhvat-pl-home-axxxl"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
