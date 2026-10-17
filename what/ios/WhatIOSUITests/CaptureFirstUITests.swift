import XCTest
import UIKit

final class CaptureFirstUITests: XCTestCase {
#if REVIEW_HANDOFF_QA
    private let chickmarkBundleID = "ru.arvectum.tools.chickmark.reviewqa"
#else
    private let chickmarkBundleID = "ru.arvectum.tools.habits"
#endif

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
    func testExplicitNoteHandoffOpensChickMarkPreviewWithoutAutoSaving() throws {
        // Requires the independent ChickMark simulator QA build to be installed.
        let app = XCUIApplication()
        app.launch()
        let plus = app.buttons["what.new.text"]
        XCTAssertTrue(plus.waitForExistence(timeout: 10))
        plus.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 7))
        editor.tap()
        let marker = "Cross app review \(UUID().uuidString.prefix(7))"
        editor.typeText(marker)
        app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch.tap()
        let library = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 7))
        library.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 7))
        let send = app.buttons["what.note.sendToChickMark"].firstMatch
        XCTAssertTrue(send.waitForExistence(timeout: 7))
        send.tap()
        let confirm = app.buttons["what.note.handoff.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 7))
        confirm.tap()

        let chickmark = XCUIApplication(bundleIdentifier: chickmarkBundleID)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let popup = springboard.alerts.firstMatch
        if popup.waitForExistence(timeout: 4) {
            let paste = popup.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@ OR label == %@ OR label == %@",
                "Allow Paste", "Разрешить вставку", "Allow", "Разрешить"
            )).firstMatch
            if paste.exists { paste.tap() }
        }
        let paste = chickmark.buttons.matching(NSPredicate(format:
            "label == %@", "Вставить заметку"
        )).firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 14),
                      "ChickMark must ask permission before reading temporary clipboard")
        paste.tap()
        let pastePrompt = springboard.alerts.firstMatch
        if pastePrompt.waitForExistence(timeout: 3) {
            let allow = pastePrompt.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@ OR label == %@ OR label == %@",
                "Allow Paste", "Разрешить вставку", "Allow", "Разрешить"
            )).firstMatch
            if allow.exists { allow.tap() }
        }
        let recipientConfirm = chickmark.buttons["chickmark.noteReview.confirm"]
        let recipientIsShowing = recipientConfirm.waitForExistence(timeout: 12)
        if !recipientIsShowing {
            print("REVIEW_RECEIVER_DEBUG_TREE_START")
            print(chickmark.debugDescription)
            print("REVIEW_RECEIVER_SPRINGBOARD_TREE")
            print(springboard.debugDescription)
            print("REVIEW_RECEIVER_DEBUG_TREE_END")
        }
        XCTAssertTrue(recipientIsShowing,
                      "ChickMark should open a confirm-before-save preview")
        if recipientIsShowing {
            XCTAssertTrue(chickmark.staticTexts[marker].exists,
                          "Private note must arrive fully in the recipient preview")
            chickmark.buttons.matching(NSPredicate(format: "label == %@", "Отмена"))
                .firstMatch.tap() // Do not create an unnecessary reminder.
            XCTAssertFalse(recipientConfirm.exists)
        }
    }

    func testExplicitNoteHandoffSavesOrHandlesDeniedNotifications() throws {
        let app = XCUIApplication()
        app.launch()
        let add = app.buttons["what.new.text"]
        XCTAssertTrue(add.waitForExistence(timeout: 12))
        add.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 8))
        editor.tap()
        let marker = "Verified imported review \(UUID().uuidString.prefix(7))"
        editor.typeText(marker)
        app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch.tap()
        let library = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 8))
        library.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 8))
        app.buttons["what.note.sendToChickMark"].firstMatch.tap()
        let send = app.buttons["what.note.handoff.confirm"]
        XCTAssertTrue(send.waitForExistence(timeout: 8))
        send.tap()
        let chickmark = XCUIApplication(bundleIdentifier: chickmarkBundleID)
        let paste = chickmark.buttons.matching(NSPredicate(format:
            "label == %@", "Вставить заметку"
        )).firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 14))
        paste.tap()
        let confirm = chickmark.buttons["chickmark.noteReview.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 14),
                      "Paste must not create the task until user confirms")
        XCTAssertTrue(chickmark.staticTexts[marker].exists)
        confirm.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        if alert.waitForExistence(timeout: 6) {
            // Exact labels: `CONTAINS Allow` accidentally selects `Don’t Allow`.
            let allow = alert.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@ OR label == %@ OR label == %@",
                "Allow", "Разрешить", "Allow Notifications", "Разрешить уведомления"
            )).firstMatch
            XCTAssertTrue(allow.exists, "Notification permission alert must be accepted, not denied")
            allow.tap()
        }
        let deniedAlert = chickmark.alerts.matching(NSPredicate(format:
            "label == %@", "Не удалось добавить"
        )).firstMatch
        if deniedAlert.waitForExistence(timeout: 3) {
            XCTAssertTrue(chickmark.staticTexts.matching(NSPredicate(format:
                "label CONTAINS %@", "Разрешите уведомления ChickMark"
            )).firstMatch.exists,
            "Denied notification permission must not silently create a task")
            XCTAssertTrue(confirm.exists, "The unsaved preview must remain available")
            return
        }
        let sourceRow = chickmark.buttons.matching(NSPredicate(format:
            "label CONTAINS %@", "Открыть заметку из Ухвата"
        )).firstMatch
        XCTAssertTrue(sourceRow.waitForExistence(timeout: 8),
                      "On an authorized simulator, the imported one-off must expose full text")
        XCTAssertTrue(chickmark.staticTexts.matching(NSPredicate(format:
            "label BEGINSWITH %@", "Разобрать заметку:"
        )).firstMatch.exists)
    }

    func testImportedChickMarkNoteLinkBackOpensOriginalInWhat() throws {
        // Run only after a successful synthetic QA import in the other test.
        let chickmark = XCUIApplication(bundleIdentifier: chickmarkBundleID)
        chickmark.launch()
        let openImportedNote = chickmark.buttons.matching(NSPredicate(format:
            "label CONTAINS %@", "Открыть заметку из Ухвата"
        )).firstMatch
        XCTAssertTrue(openImportedNote.waitForExistence(timeout: 14),
                      "Imported note must remain accessible via an obvious button after relaunch")
        openImportedNote.tap()
        let fullTextLink = chickmark.links["Открыть оригинал в Ухвате"].firstMatch
        XCTAssertTrue(fullTextLink.waitForExistence(timeout: 8),
                      "Saved review note must preserve a link to the original")
        fullTextLink.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let popup = springboard.alerts.firstMatch
        if popup.waitForExistence(timeout: 3) {
            let open = popup.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@ OR label == %@ OR label == %@",
                "Open", "Открыть", "Continue", "Продолжить"
            )).firstMatch
            if open.exists { open.tap() }
        }
        let source = XCUIApplication(bundleIdentifier: "ru.arvectum.tools.what.reviewqa")
        // SwiftUI exposes this panel as StaticText and Button children,
        // not as an enclosing accessibility Other.
        let highlightedOriginal = source.staticTexts.matching(NSPredicate(format:
            "identifier == %@ AND (label == %@ OR label == %@)",
            "what.reminder.target", "Original note", "Исходная заметка"
        )).firstMatch
        if !highlightedOriginal.waitForExistence(timeout: 10) {
            print("LINK_BACK_SOURCE_APP_TREE_START")
            print(source.debugDescription)
            print("LINK_BACK_SOURCE_APP_TREE_END")
        }
        XCTAssertTrue(highlightedOriginal.exists,
                      "Opening the review's link must navigate to the source note")
    }

    func testSavedChickMarkReviewOpensOriginalSourceNote() throws {
        let source = XCUIApplication()
        source.launch()
        let newText = source.buttons["what.new.text"]
        XCTAssertTrue(newText.waitForExistence(timeout: 12))
        newText.tap()
        let editor = source.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 7))
        editor.tap()
        let marker = "Source deep link \(UUID().uuidString.prefix(8))"
        editor.typeText(marker)
        source.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch.tap()
        let library = source.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 8))
        library.tap()
        XCTAssertTrue(source.staticTexts[marker].waitForExistence(timeout: 8))
        source.buttons["what.note.sendToChickMark"].firstMatch.tap()
        let submit = source.buttons["what.note.handoff.confirm"]
        XCTAssertTrue(submit.waitForExistence(timeout: 8))
        submit.tap()
        let recipient = XCUIApplication(bundleIdentifier: chickmarkBundleID)
        let paste = recipient.buttons["chickmark.noteReview.paste"]
        XCTAssertTrue(paste.waitForExistence(timeout: 14))
        paste.tap()
        let create = recipient.buttons["chickmark.noteReview.confirm"]
        XCTAssertTrue(create.waitForExistence(timeout: 15))
        XCTAssertTrue(recipient.staticTexts[marker].exists)
        create.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let systemAlert = springboard.alerts.firstMatch
        if systemAlert.waitForExistence(timeout: 4) {
            let allowed = systemAlert.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@ OR label == %@ OR label == %@",
                "Allow", "Разрешить", "Allow Notifications", "Разрешить уведомления"
            )).firstMatch
            XCTAssertTrue(allowed.exists)
            allowed.tap()
        }
        let imported = recipient.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND value CONTAINS %@",
            "chickmark.noteReview.open.", marker
        )).firstMatch
        XCTAssertTrue(imported.waitForExistence(timeout: 12),
                      "Imported one-off must offer a direct source-text action")
        imported.tap()
        let link = recipient.links.matching(NSPredicate(format:
            "label == %@", "Открыть оригинал в Ухвате"
        )).firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 8),
                      "Full text and original deep link must be accessible")
        let displayedText = recipient.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", marker)).firstMatch
        XCTAssertTrue(displayedText.exists,
                      "Imported full text must be visible in the details sheet")
        link.tap()
        let revealed = source.descendants(matching: .any)
            .matching(identifier: "what.reminder.target").firstMatch
        let didReveal = revealed.waitForExistence(timeout: 10)
        if !didReveal {
            print("SOURCE_DEEPLINK_DEBUG_BEGIN")
            print("SOURCE_APP_TREE: \(source.debugDescription)")
            print("RECIPIENT_APP_TREE: \(recipient.debugDescription)")
            print("SPRINGBOARD_TREE: \(XCUIApplication(bundleIdentifier: "com.apple.springboard").debugDescription)")
            print("SOURCE_DEEPLINK_DEBUG_END")
        }
        XCTAssertTrue(didReveal, "Source app must open original note by UUID")
        XCTAssertTrue(source.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", marker))
            .firstMatch.exists, "Original note must remain in UhWhat")
        XCTAssertFalse(source.buttons["what.note.handoff.confirm"].exists,
                       "An old send modal must not hide the returned original")

        // Resending the exact same note UUID must open a duplicate warning,
        // never schedule a second one-off task.
        let sendAgain = source.buttons["what.note.sendToChickMark"].firstMatch
        XCTAssertTrue(sendAgain.waitForExistence(timeout: 6))
        sendAgain.tap()
        let confirmAgain = source.buttons["what.note.handoff.confirm"]
        XCTAssertTrue(confirmAgain.waitForExistence(timeout: 6))
        confirmAgain.tap()
        let pasteAgain = recipient.buttons["chickmark.noteReview.paste"]
        XCTAssertTrue(pasteAgain.waitForExistence(timeout: 12))
        pasteAgain.tap()
        let duplicate = recipient.staticTexts["Заметка уже передана"]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 10),
                      "A confirmed imported UUID must show persistent duplicate notice")
        XCTAssertFalse(recipient.buttons["chickmark.noteReview.confirm"].isEnabled,
                       "An already-imported note must not be confirmed twice")
    }

    func testChickMarkHandoffShowsStableConfirmationBeforeAnyTransfer() throws {
        let app = XCUIApplication()
        app.launch()
        let plus = app.buttons["what.new.text"]
        XCTAssertTrue(plus.waitForExistence(timeout: 12))
        plus.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 8))
        editor.tap()
        let marker = "Handoff UI \(UUID().uuidString.prefix(8))"
        editor.typeText(marker)
        app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch.tap()
        let library = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 8))
        library.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 8))
        let send = app.buttons["what.note.sendToChickMark"].firstMatch
        XCTAssertTrue(send.waitForExistence(timeout: 8))
        send.tap()
        let confirm = app.buttons["what.note.handoff.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 8),
                      "Sending must require a visible explicit consent step")
        XCTAssertTrue(app.staticTexts[marker].exists)
        app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Отмена", "Cancel"
        )).firstMatch.tap()
        XCTAssertTrue(app.staticTexts[marker].waitForExistence(timeout: 5))
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
