import XCTest

/// QA on isolated iPad/Duo simulator (not actual hinge or physical camera).
final class AdaptiveLayoutUITests: XCTestCase {
    /// Run on an isolated iPad simulator configured via simctl ui
    /// content_size accessibility-extra-extra-extra-large. It checks that
    /// the capture-first UX and empty-note editor remain usable without
    /// modifying camera/microphone permissions or writing new user notes.
    func testCaptureHomeSystemAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        XCTAssertTrue(app.buttons["what.record.primary"].waitForExistence(timeout: 12))

        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("WHAT_AX_AUDIT issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    /// Debug-only ephemeral text/video fixture; no user files or capture.
    private func openedPopulatedLibrary() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "--qa-design-filled-library"
        ]
        app.launch()
        let library = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
            "Все заметки", "All notes"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 15))
        library.tap()
        XCTAssertTrue(app.buttons["what.library.filterMenu"].waitForExistence(timeout: 12))
        let note = app.staticTexts["Нужно сверить план на неделю и список важных задач"]
        let notesList = app.collectionViews.firstMatch
        XCTAssertTrue(notesList.exists)
        for _ in 0..<5 where !note.exists { notesList.swipeUp() }
        XCTAssertTrue(note.waitForExistence(timeout: 5), "Text note must appear")
        let missingVideo = app.staticTexts["Видео недоступно"]
        for _ in 0..<6 where !missingVideo.exists {
            notesList.swipeUp()
        }
        XCTAssertTrue(missingVideo.exists,
            "Synthetic missing-video state must be explicit")
        return app
    }

    func testPopulatedMixedLibraryTypographyAndSemanticsAudit() throws {
        let app = openedPopulatedLibrary()
        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("WHAT_FILLED_CONTENT_AX issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    /// The AX-size custom action bar replaces UIKit's constrained toolbar.
    /// This full four-category system audit must run, never skip or mask
    /// anonymous failures.
    func testPopulatedMixedLibrarySystemAccessibilityAudit() throws {
        let app = openedPopulatedLibrary()
        for identifier in ["what.library.backToRecord", "what.library.newText",
                           "what.library.settings"] {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.waitForExistence(timeout: 5), identifier)
            XCTAssertGreaterThanOrEqual(control.frame.width, 44, identifier)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44, identifier)
        }
        // One fully readable selection menu at AXXXL must leave room for
        // the note list on the physical iPhone 13 viewport.
        let menu = app.buttons["what.library.filterMenu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 8))
        XCTAssertTrue(menu.isHittable)
        XCTAssertGreaterThanOrEqual(menu.frame.height, 44)
        XCTAssertGreaterThanOrEqual(menu.frame.minX, app.frame.minX - 1)
        XCTAssertLessThanOrEqual(menu.frame.maxX, app.frame.maxX + 1)
        XCTAssertTrue(menu.label.contains("Все"))

        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("WHAT_FILLED_FULL_AX issue=\(issue.compactDescription) " +
                  "detail=\(issue.detailedDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    func testPopulatedLibraryDiagnosticsAXXXLSystemAccessibilityAudit() throws {
        let app = openedPopulatedLibrary()
        let settings = app.buttons["what.library.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        XCTAssertTrue(settings.isHittable)
        settings.tap()
        let diagnostics = app.buttons["Диагностика синхронизации"]
        XCTAssertTrue(diagnostics.waitForExistence(timeout: 8))
        diagnostics.tap()
        let close = app.buttons["syncDiagnosticsClose"]
        XCTAssertTrue(close.waitForExistence(timeout: 10))
        // The last Watch state can be present from a previous simulator run;
        // neither case should be mistaken for live connection status.
        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("WHAT_DIAGNOSTICS_AX issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil") " +
                  "detail=\(issue.detailedDescription)")
            return false
        }
        let staleReportCaveat = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            "не проверка соединения", "not a real-time connection"
        )).firstMatch
        for _ in 0..<12 where !staleReportCaveat.exists {
            app.swipeUp()
        }
        XCTAssertTrue(staleReportCaveat.waitForExistence(timeout: 6),
                      "Diagnostics must explain that Watch data is not live")
        // Also audit the scrolled Watch report, not only the visible counts.
        try app.performAccessibilityAudit(for: categories) { issue in
            print("WHAT_DIAGNOSTICS_WATCH_AX issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil") " +
                  "detail=\(issue.detailedDescription)")
            return false
        }
        close.tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
    }

    func testPopulatedLibraryAccessibleActionsNavigateSafely() throws {
        let app = openedPopulatedLibrary()
        let add = app.buttons["what.library.newText"]
        XCTAssertTrue(add.isHittable)
        add.tap()
        let editor = app.textViews["what.text.editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 10),
                      "AX-sized New Text action must open the editor")
        let done = app.buttons.matching(NSPredicate(
            format: "label == %@ OR label == %@", "Готово", "Done"
        )).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 10))
        done.tap() // Empty draft, no note/file created.
        let back = app.buttons["what.library.backToRecord"]
        XCTAssertTrue(back.waitForExistence(timeout: 10))
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(app.buttons["what.record.primary"]
            .waitForExistence(timeout: 10), "Back returns to quick capture")
    }

    func testPopulatedLibraryAccessibleSettingsMenuOpens() throws {
        let app = openedPopulatedLibrary()
        let settings = app.buttons["what.library.settings"]
        XCTAssertTrue(settings.isHittable)
        settings.tap()
        let diagnostics = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            "Диагностика", "diagnostics"
        )).firstMatch
        XCTAssertTrue(diagnostics.waitForExistence(timeout: 10),
                      "AX-sized settings action must open original settings menu")
        // Do not choose any menu command, changing no real preferences.
    }

    func testNotesLibrarySystemAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"]
        app.launch()
        let library = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                    "Все заметки", "All notes"
        )).firstMatch
        XCTAssertTrue(library.waitForExistence(timeout: 12))
        library.tap()
        let standardFilter = app.buttons["what.filter.all"]
        let largeTextFilter = app.buttons["what.library.filterMenu"]
        XCTAssertTrue(standardFilter.waitForExistence(timeout: 3)
                      || largeTextFilter.waitForExistence(timeout: 5),
                      "Type filtering must be accessible at normal and AX sizes")

        let categories: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: categories) { issue in
            print("WHAT_LIBRARY_AX_AUDIT issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

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
        // Rare CoreSimulator launch races present a 134×291pt window (exactly
        // one-third of the expected iPhone viewport), putting the Text action
        // beneath the OS status area. Relaunch once, but never waive the
        // hittable/action assertions for a valid >=320pt phone viewport.
        if app.frame.width < 320 {
            print("WHAT_QA_ABNORMAL_WINDOW=\(app.frame); relaunching")
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
            app.launch()
        }
        XCTAssertGreaterThanOrEqual(app.frame.width, 320,
             "Simulator window must use iPhone geometry, not 134pt miniature")

        let primary = app.buttons["what.record.primary"]
        let video = app.buttons["what.new.video"]
        let text = app.buttons["what.new.text"]
        XCTAssertTrue(primary.waitForExistence(timeout: 8))
        XCTAssertTrue(video.exists)
        XCTAssertTrue(text.exists)
        XCTAssertTrue(video.isHittable)
        let hittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: text
        )
        let result = XCTWaiter.wait(for: [hittable], timeout: 6)
        if result != .completed {
            print("WHAT_TEXT_NOT_HITTABLE app=\(app.frame) button=\(text.frame)")
            print("WHAT_CAPTURE_HIT_TREE=\(app.debugDescription.prefix(12000))")
        }
        XCTAssertEqual(result, .completed,
                       "Text action must become tappable after layout settles")
        XCTAssertTrue(text.isHittable)
    }

    func testAccessibilityTextSizePreservesCaptureAndEmptyTextEditor() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge"
        ]
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
        XCTAssertTrue(["Текст заметки", "Note text"].contains(editor.label),
                      "VoiceOver editor should have a meaningful localized field name")
        XCTAssertTrue(editor.isHittable,
                      "Editor must be reachable and retain a meaningful VoiceOver label")
        // XCTest may expose a visually drawn overlay in its element query
        // even when SwiftUI marks it accessibilityHidden. Check real VO
        // focus separately; staticTexts.exists is not a VoiceOver stop test.
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
        let standardFilter = app.buttons["what.filter.all"]
        let largeTextFilter = app.buttons["what.library.filterMenu"]
        let filterVisible = standardFilter.waitForExistence(timeout: 3)
            || largeTextFilter.waitForExistence(timeout: 6)
        XCTAssertTrue(filterVisible,
                      "Unified library type filter must be available at all Dynamic Type sizes")
        XCTAssertTrue(standardFilter.exists ? standardFilter.isHittable
                      : largeTextFilter.isHittable,
                      "Filter must remain actionable")
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
