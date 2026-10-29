import XCTest

/// Turkish UI smoke with synthetic launch flags, no live microphone/Watch or user notes.
final class TurkishLocalizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testTurkishAXXXLHomeControlsWithoutRecording() {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(tr)", "-AppleLocale", "tr_TR",
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
        XCTAssertTrue(app.staticTexts["Düşünceyi yakalayın"].waitForExistence(timeout: 12))
        let primary = app.buttons["what.record.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 12))
        XCTAssertTrue(primary.isHittable)
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.isHittable)
        XCTAssertEqual(text.label, "Yeni metin notu")
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.isHittable)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.isHittable)
        XCTAssertTrue(library.label.hasPrefix("Tüm notlar, "), library.label)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "uhvat-tr-home-axxxl"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
