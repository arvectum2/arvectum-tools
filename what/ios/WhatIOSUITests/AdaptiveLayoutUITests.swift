import XCTest

/// QA on isolated iPad/Duo simulator (not actual hinge or physical camera).
final class AdaptiveLayoutUITests: XCTestCase {
    /// Run on an isolated iPad simulator configured via simctl ui
    /// content_size accessibility-extra-extra-extra-large. It checks that
    /// the capture-first UX and empty-note editor remain usable without
    /// modifying camera/microphone permissions or writing new user notes.
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
                    "Мои записи", "My recordings"
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
                        "Мои записи", "My recordings")
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
