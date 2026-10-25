import XCTest

/// Missing baseline + French iPhone UI coverage: synthetic home, no recording.
final class CoreLanguageCoverageUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func checkHome(
        language: String,
        locale: String,
        title: String,
        newText: String,
        allNotesPrefix: String
    ) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            // Speech recognition is intentionally independent of UI language.
            "-what.transcription.locale", "en-US",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-spanish-axxxl-home"
        ]
        app.launch()

        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 12))
        let record = app.buttons["what.record.primary"]
        XCTAssertTrue(record.waitForExistence(timeout: 12))
        XCTAssertTrue(record.isHittable)
        // Do not tap Record: tests must never access microphone/real data.
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.exists)
        XCTAssertTrue(text.isHittable)
        XCTAssertEqual(text.label, newText)
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.isHittable)
        let library = app.buttons["what.open.library"]
        XCTAssertTrue(library.isHittable)
        XCTAssertTrue(library.label.hasPrefix(allNotesPrefix), library.label)

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "uhvat-\(language)-axxxl-home"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testRussianBaselineHome() {
        checkHome(language: "ru", locale: "ru_RU",
                  title: "Ухвати мысль",
                  newText: "Создать текстовую заметку",
                  allNotesPrefix: "Все заметки, ")
    }

    @MainActor
    func testEnglishBaselineHome() {
        checkHome(language: "en", locale: "en_US",
                  title: "Catch that thought",
                  newText: "New text note",
                  allNotesPrefix: "All notes, ")
    }

    @MainActor
    func testFrenchHomeWithIndependentEnglishDictation() {
        checkHome(language: "fr", locale: "fr_FR",
                  title: "Attrape cette pensée",
                  newText: "Nouvelle note textuelle",
                  allNotesPrefix: "Toutes les notes, ")
    }
}
