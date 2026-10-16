import XCTest
import UIKit

final class CaptureFirstUITests: XCTestCase {
    func testCaptureFirstHomeAndLibraryBackNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let start = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Начать запись", "Start recording")
        ).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 10),
                      "The recording button must be immediately visible at launch.")

        let saved = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(saved.exists,
                      "The saved-notes library must always be reachable.")
        saved.tap()

        let returnToRecording = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Вернуться к быстрой записи", "Back to quick recording")
        ).firstMatch
        XCTAssertTrue(returnToRecording.waitForExistence(timeout: 5),
                      "The library must offer a one-tap return to capture.")
        XCTAssertTrue(app.navigationBars["Ухват"].exists ||
                      app.navigationBars["UhWhat?"].exists)
        returnToRecording.tap()

        XCTAssertTrue(start.waitForExistence(timeout: 5))
        XCTAssertTrue(saved.exists)
    }
    func testTypedNoteFromPlusPersistsAfterOpeningLibrary() throws {
        let app = XCUIApplication()
        app.launch()

        let plus = app.buttons["what.new.text"]
        XCTAssertTrue(plus.waitForExistence(timeout: 10), "Text + must be visible on home.")
        plus.tap()

        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        let marker = "Typed note UITest 20261016"
        editor.typeText(marker)

        let close = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Готово", "Done")
        ).firstMatch
        XCTAssertTrue(close.exists)
        close.tap()

        let saved = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 10),
                      "Locally autosaved note must appear in the unified inbox.")
    }
    func testIPadLandscapePreservesCaptureTextEditorAndLibrary() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("iPad layout acceptance is specific to iPad.")
        }
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()

        let capture = app.buttons["what.record.primary"]
        let addText = app.buttons["what.new.text"]
        XCTAssertTrue(capture.waitForExistence(timeout: 10))
        XCTAssertTrue(addText.exists)
        XCTAssertTrue(capture.isHittable)
        XCTAssertTrue(addText.isHittable)

        addText.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        let done = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Готово", "Done")
        ).firstMatch
        XCTAssertTrue(done.exists)
        done.tap()

        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 5))
        XCTAssertTrue(library.isHittable)
        library.tap()
        let back = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Вернуться к быстрой записи", "Back to quick recording")
        ).firstMatch
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
    }

    func testTextNoteCanOpenReminderPresetsWithoutPermissionPrompt() throws {
        let app = XCUIApplication()
        app.launch()
        let plus = app.buttons["what.new.text"]
        XCTAssertTrue(plus.waitForExistence(timeout: 10))
        plus.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Reminder menu test")
        let done = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "Готово", "Done")
        ).firstMatch
        done.tap()
        let library = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                        "Мои записи", "My recordings")
        ).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 5))
        library.tap()
        let reminder = app.buttons["what.reminder.menu"].firstMatch
        XCTAssertTrue(reminder.waitForExistence(timeout: 8))
        reminder.tap()
        let option = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Через 1 час", "In 1 hour")
        ).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        // Do not select a time; permission must only be requested on opt-in.
        XCTAssertEqual(app.alerts.count, 0)
    }

    func testLongPressGoesToVideoNotAudio() throws {
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Начать запись", "Start recording")
        ).firstMatch
        XCTAssertTrue(record.waitForExistence(timeout: 10))
        record.press(forDuration: 0.8)

        let video = app.navigationBars.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Видеозаметка", "Video note")
        ).firstMatch
        // Simulator hardware may have no camera. In that case the Video
        // recording sheet reports a camera error instead of a live preview.
        // Both outcomes prove that Hold routes to Video, never to Audio.
        let videoHardwareAlert = app.alerts.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Видеозапись", "Video capture")
        ).firstMatch
        let routedToVideo = video.waitForExistence(timeout: 3)
            || videoHardwareAlert.waitForExistence(timeout: 3)
        XCTAssertTrue(routedToVideo,
                      "Holding the round button must open Video or a Video-specific hardware alert.")
        let audio = app.navigationBars.matching(
            NSPredicate(format: "label == %@ OR label == %@",
                        "Новая запись", "New recording")
        ).firstMatch
        XCTAssertFalse(audio.exists, "A long press must not start audio.")
    }
}
