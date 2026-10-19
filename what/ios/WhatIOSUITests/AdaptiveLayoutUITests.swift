import XCTest

/// QA on isolated iPad/Duo simulator (not actual hinge or physical camera).
final class AdaptiveLayoutUITests: XCTestCase {
    /// Run on an isolated iPad simulator configured via simctl ui
    /// content_size accessibility-extra-extra-extra-large. It checks that
    /// the capture-first UX and empty-note editor remain usable without
    /// modifying camera/microphone permissions or writing new user notes.
    func testCaptureAccessibilityLabelsAndActions() {
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons["what.record.primary"]
        XCTAssertTrue(record.waitForExistence(timeout: 12))
        XCTAssertTrue(
            ["Начать запись", "Start recording"].contains(record.label),
            "Primary VoiceOver element must describe audio capture"
        )
        let video = app.buttons["what.new.video"]
        XCTAssertTrue(video.exists)
        XCTAssertTrue(["Видео", "Video"].contains(video.label))
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(text.exists)
        XCTAssertTrue(
            ["Создать текстовую заметку", "New text note"].contains(text.label)
        )
        XCTAssertTrue(record.isHittable)
        XCTAssertTrue(video.isHittable)
        XCTAssertTrue(text.isHittable)
    }

#if compiler(>=6.4)
    @MainActor
    func testActualVoiceOverCaptureSpeech() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("Actual VoiceOver requires iOS 27")
        }
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        XCTAssertTrue(app.buttons["what.record.primary"].waitForExistence(timeout: 12))
        let service = XCUIDevice.shared.voiceOverService
        defer { _ = try? service.disable() }
        _ = try? service.disable()
        _ = try service.enable()
        var spoken = [try service.currentSpeech().utterance]
        for _ in 1..<7 { spoken.append(try service.moveForward().utterance) }
        print("WHAT_VOICEOVER_SPEECH=\(spoken)")
        XCTAssertTrue(spoken.contains {
            $0.localizedCaseInsensitiveContains("Начать запись") ||
            $0.localizedCaseInsensitiveContains("Start recording")
        }, "VoiceOver should reach the primary audio action")
    }
#endif

    func testCaptureAlternativesAreDiscoverable() {
        let app = XCUIApplication()
        app.launch()

        let primary = app.buttons["what.record.primary"]
        let video = app.buttons["what.new.video"]
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(primary.waitForExistence(timeout: 8))
        XCTAssertTrue(video.exists)
        XCTAssertTrue(text.exists)
        XCTAssertTrue(video.isHittable)
        XCTAssertTrue(text.isHittable)
    }

    func testAccessibilityTextSizePreservesCaptureAndEmptyTextEditor() throws {
        let app = XCUIApplication()
        app.launch()
        let capture = app.buttons["what.record.primary"]
        XCTAssertTrue(capture.waitForExistence(timeout: 20))
        XCTAssertTrue(capture.isHittable, "Primary capture must remain reachable")
        let plus = app.buttons["what.new.text"]
        XCTAssertTrue(plus.waitForExistence(timeout: 10))
        XCTAssertTrue(plus.isHittable, "Large Type must not hide text note action")
        plus.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 15),
                      "Text editor must be available in accessibility sizes")
        let done = app.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        done.tap() // Empty draft must not create a note.
        XCTAssertTrue(capture.waitForExistence(timeout: 10))
        let library = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                    "Все заметки", "All notes"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        XCTAssertTrue(library.isHittable)
        library.tap()
        let allFilter = app.buttons["what.filter.all"]
        XCTAssertTrue(allFilter.waitForExistence(timeout: 10),
                      "Unified library type filters must remain discoverable")
        XCTAssertTrue(allFilter.isHittable, "Filter must remain actionable")
        let back = app.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@",
                    "Вернуться к быстрой записи", "Back to quick recording"
        )).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
        XCTAssertTrue(capture.waitForExistence(timeout: 10))
    }

    func testCaptureAndUnifiedLibraryKeepStateAcrossRotation() throws {
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Начать запись", "Start recording")
        ).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 15))
        let saved = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Все заметки", "All notes")
        ).firstMatch
        XCTAssertTrue(saved.exists)
        saved.tap()
        let back = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Вернуться к быстрой записи", "Back to quick recording")
        ).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        let newText = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Создать текстовую заметку", "New text note")
        ).firstMatch
        XCTAssertTrue(newText.waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        XCTAssertTrue(newText.exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        back.tap()
        XCTAssertTrue(record.waitForExistence(timeout: 10))
    }
}
