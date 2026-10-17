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
    func testUnifiedLibraryTypeChipsFilterTypedNotesWithoutDeletingThem() throws {
        let app = XCUIApplication()
        app.launch()
        let add = app.buttons["what.new.text"]
        XCTAssertTrue(add.waitForExistence(timeout: 12))
        add.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 8))
        editor.tap()
        let marker = "Type filter UI " + UUID().uuidString.prefix(7)
        editor.typeText(marker)
        let done = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch
        done.tap()

        let library = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()

        let all = app.buttons["what.filter.all"]
        let text = app.buttons["what.filter.text"]
        let audio = app.buttons["what.filter.audio"]
        let video = app.buttons["what.filter.video"]
        XCTAssertTrue(all.waitForExistence(timeout: 10))
        XCTAssertTrue(text.exists && audio.exists && video.exists)
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 10))

        audio.tap()
        XCTAssertFalse(app.staticTexts[marker].exists,
                       "Audio-only filter must not show text notes")
        text.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 5))
        video.tap()
        XCTAssertFalse(app.staticTexts[marker].exists,
                       "Video-only filter must not show text notes")
        let reset = app.buttons["what.filter.reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5),
                      "Empty filtered folder must offer a one-tap reset")
        reset.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 5))
        XCTAssertTrue(all.exists)
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
    func testIPadRotationPreservesVisibleCaptureAndTextControls() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("Rotation acceptance is specific to iPad")
        }
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        app.launch()

        let capture = app.buttons["what.record.primary"]
        let plus = app.buttons["what.new.text"]
        let library = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        for orientation: UIDeviceOrientation in [.portrait, .landscapeRight, .portrait] {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(capture.waitForExistence(timeout: 12),
                          "Capture must exist after rotating iPad: \(orientation.rawValue)")
            XCTAssertTrue(capture.isHittable, "Capture must be visible after rotation")
            XCTAssertTrue(plus.isHittable, "Text + must remain visible after rotation")
            XCTAssertTrue(library.isHittable, "Library must remain visible after rotation")
        }
        plus.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertTrue(editor.isHittable, "iPad text editor must not be clipped")
        let done = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch
        XCTAssertTrue(done.isHittable)
        done.tap()
        XCTAssertTrue(capture.waitForExistence(timeout: 7))
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

    func testAutoFollowUpSettingsAreExplicitAndDoNotPromptOnOpen() throws {
        let app = XCUIApplication()
        app.launch()
        let library = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 10))
        library.tap()
        let settings = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@",
            "Настройки и диагностика", "App settings and diagnostics"
        )).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        settings.tap()
        let automation = app.buttons["what.settings.autoFollowUp"]
        XCTAssertTrue(automation.waitForExistence(timeout: 8),
                      "Automatic follow-up should be discoverable in settings")
        automation.tap()
        let off = app.buttons.matching(NSPredicate(format:
            "label CONTAINS %@ OR label CONTAINS %@", "Выключено", "Off"
        )).firstMatch
        let one = app.buttons.matching(NSPredicate(format:
            "label CONTAINS %@ OR label CONTAINS %@", "Через 1 час", "After 1 hour"
        )).firstMatch
        XCTAssertTrue(off.waitForExistence(timeout: 6),
                      "The opt-in rule must always provide Off")
        XCTAssertTrue(one.exists, "One-hour opt-in must be available")
        // Merely opening settings must not prompt for notification access.
        XCTAssertEqual(app.alerts.count, 0)
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

        // iOS 27 simulator exposes NavigationStack's title as an
        // accessibility identifier, not necessarily a label. Test both.
        let video = app.navigationBars.matching(
            NSPredicate(format:
                "identifier == %@ OR identifier == %@ OR label == %@ OR label == %@",
                "Видеозаметка", "Video note", "Видеозаметка", "Video note")
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

        // The simulator may asynchronously dismiss its hardware-unavailable
        // video sheet while camera permissions resolve. End only this
        // synthetic UI-test app instance rather than attempting to tap a
        // button that may disappear during animation.
        app.terminate()
    }
}
