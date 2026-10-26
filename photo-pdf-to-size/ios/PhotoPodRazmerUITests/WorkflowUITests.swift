import XCTest

/// Deterministic simulator workflows. The app generates synthetic documents in DEBUG only.
final class WorkflowUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ fixture: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)",
            "-AppleLocale", "ru_RU",
            fixture
        ]
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 2) { decline.tap() }
        return app
    }

    private func assertPrimarySaveVisible(fixture: String, action: String) {
        let app = launch(fixture)
        let process = app.buttons[action]
        XCTAssertTrue(process.waitForExistence(timeout: 8))
        process.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))

        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.waitForExistence(timeout: 8))
        XCTAssertTrue(save.isHittable, "Save should be visible without scrolling")
        XCTAssertTrue(
            app.buttons["edit-settings-button"].isHittable,
            "Settings must remain reachable without scrolling"
        )
        XCTAssertTrue(
            app.buttons["ad-privacy-settings-button"].isHittable,
            "Privacy controls must remain reachable"
        )
        XCTAssertLessThanOrEqual(save.frame.height, 96,
                                 "Sticky save must not consume the viewport")
        XCTAssertLessThanOrEqual(
            save.frame.maxY, app.frame.maxY + 1,
            "Save cannot fall below the visible viewport"
        )
        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = fixture == "--qa-pdf-fixture"
            ? "design-code-PDF-result" : "design-code-photo-result"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

#if compiler(>=6.4)
    @MainActor
    func testActualVoiceOverPhotoResultSpeech() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("Actual VoiceOver requires iOS 27")
        }
        let app = launch("--qa-photo-fixture")
        let process = app.buttons["Уменьшить фото"]
        XCTAssertTrue(process.waitForExistence(timeout: 10))
        process.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))
        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.isHittable)
        XCTAssertEqual(save.label, "Сохранить файл")

        let service = XCUIDevice.shared.voiceOverService
        defer { _ = try? service.disable() }
        _ = try? service.disable()
        _ = try service.enable()
        var spoken = [try service.currentSpeech().utterance]
        for _ in 1..<7 { spoken.append(try service.moveForward().utterance) }
        print("PHOTO_VOICEOVER_RESULT=\(spoken)")
        XCTAssertFalse(spoken.contains {
            $0.contains("ArvectumWordmark") ||
            $0.trimmingCharacters(in: .whitespacesAndNewlines) == "Image"
        }, "Decorative logo and image thumbnail must not create speech stops")
        XCTAssertTrue(spoken.contains {
            $0.localizedCaseInsensitiveContains("ГОТОВО") ||
            $0.localizedCaseInsensitiveContains("Изменить настройки")
        }, "Result heading or settings must be spoken")
    }
#endif

#if compiler(>=6.4)
    @MainActor
    func testActualVoiceOverPDFResultSpeech() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("Actual VoiceOver requires iOS 27")
        }
        let app = launch("--qa-pdf-fixture")
        let process = app.buttons["Уменьшить PDF"]
        XCTAssertTrue(process.waitForExistence(timeout: 10))
        process.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))
        XCTAssertEqual(app.buttons["result-save-primary"].label, "Сохранить файл")

        let service = XCUIDevice.shared.voiceOverService
        defer { _ = try? service.disable() }
        _ = try? service.disable()
        _ = try service.enable()
        var spoken = [try service.currentSpeech().utterance]
        for _ in 1..<5 { spoken.append(try service.moveForward().utterance) }
        print("PDF_VOICEOVER_RESULT=\(spoken)")
        XCTAssertTrue(spoken.contains { $0.localizedCaseInsensitiveContains("PDF подготовлен") ||
                                         $0.localizedCaseInsensitiveContains("PDF уже подходит") },
                      "PDF result status must be announced")
        XCTAssertFalse(spoken.contains { $0.contains("ArvectumWordmark") ||
                                         $0.trimmingCharacters(in: .whitespacesAndNewlines) == "Image" },
                       "PDF preview and brand are decorative")
    }
#endif

    private func auditResultAccessibility(fixture: String, processAction: String) throws {
        // App-owned result UI: exclude the external Yandex creative and the
        // App Store update prompt; they have separate integration tests.
        // Keep ALL four system audits including textClipped enabled.
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            fixture, "--store-screenshot-clean"
        ]
        app.launch()
        let process = app.buttons[processAction]
        XCTAssertTrue(process.waitForExistence(timeout: 8))
        process.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))
        XCTAssertTrue(app.buttons["result-save-primary"].isHittable)

        let auditTypes: XCUIAccessibilityAuditType = [
            .sufficientElementDescription, .hitRegion, .trait, .textClipped
        ]
        try app.performAccessibilityAudit(for: auditTypes) { issue in
            print("PHOTO_PDF_AX_AUDIT fixture=\(fixture) issue=\(issue.compactDescription) " +
                  "element=\(issue.element?.description ?? "nil")")
            return false
        }
    }

    func testPhotoResultSystemAccessibilityAudit() throws {
        try auditResultAccessibility(fixture: "--qa-photo-fixture",
                                     processAction: "Уменьшить фото")
    }

    func testPDFResultSystemAccessibilityAudit() throws {
        try auditResultAccessibility(fixture: "--qa-pdf-fixture",
                                     processAction: "Уменьшить PDF")
    }

    func testPhotoSaveIsVisibleWithoutScrolling() {
        assertPrimarySaveVisible(
            fixture: "--qa-photo-fixture",
            action: "Уменьшить фото"
        )
    }

    func testPDFSaveIsVisibleWithoutScrolling() {
        assertPrimarySaveVisible(
            fixture: "--qa-pdf-fixture",
            action: "Уменьшить PDF"
        )
    }

    /// Exercise the actual system Files exporter, not just the result CTA.
    /// This uses a synthetic local fixture and a disposable QA simulator.
    private func assertExportCompletes(fixture: String, processAction: String) {
        let app = launch(fixture)
        XCTAssertTrue(app.buttons[processAction].waitForExistence(timeout: 8))
        app.buttons[processAction].tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))

        let success = app.descendants(matching: .any)["export-success"]
        XCTAssertFalse(success.exists, "Do not report success before saving")
        app.buttons["result-save-primary"].tap()

        // The system FileExporter button is separate from the in-app CTA.
        let systemSave = app.buttons["Сохранить"]
        XCTAssertTrue(
            systemSave.waitForExistence(timeout: 12),
            "System Files save UI did not open"
        )
        XCTAssertFalse(success.exists, "Opening the picker does not save")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = fixture == "--qa-pdf-fixture"
            ? "PDF system Files exporter" : "Photo system Files exporter"
        attachment.lifetime = .keepAlways
        add(attachment)
        systemSave.tap()
        let replace = app.buttons["Заменить"]
        if replace.waitForExistence(timeout: 2) { replace.tap() }

        XCTAssertTrue(
            success.waitForExistence(timeout: 12),
            "Success must follow a completed Files export"
        )
        XCTAssertTrue(app.buttons["result-save-primary"].isHittable)
    }

    func testPhotoFileExporterAndSuccessFeedback() {
        assertExportCompletes(
            fixture: "--qa-photo-fixture",
            processAction: "Уменьшить фото"
        )
    }

    func testPDFFileExporterAndSuccessFeedback() {
        assertExportCompletes(
            fixture: "--qa-pdf-fixture",
            processAction: "Уменьшить PDF"
        )
    }

    /// The two deterministic ad states must not obscure export or privacy.
    /// This covers UI geometry only: no real network ads or impressions.
    private func assertResultAdState(_ state: String) {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU",
            "--qa-photo-fixture"
        ]
        app.launchEnvironment["ARVECTUM_RESULT_AD_QA_FIXTURE"] = state
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 2) { decline.tap() }

        XCTAssertTrue(app.buttons["Уменьшить фото"].waitForExistence(timeout: 8))
        app.buttons["Уменьшить фото"].tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))

        let save = app.buttons["result-save-primary"]
        XCTAssertTrue(save.isHittable)
        XCTAssertLessThanOrEqual(save.frame.maxY, app.frame.maxY + 1)
        XCTAssertTrue(app.buttons["ad-privacy-settings-button"].isHittable)
        XCTAssertTrue(app.buttons["edit-settings-button"].isHittable)
        let fixtureID = state == "loaded" ? "result-ad-loaded-qa" : "result-ad-no-fill"
        let fixture = app.descendants(matching: .any)[fixtureID]
        XCTAssertTrue(fixture.waitForExistence(timeout: 8))
        if state == "loaded" {
            XCTAssertGreaterThanOrEqual(fixture.frame.height, 178)
            XCTAssertLessThanOrEqual(fixture.frame.height, 182)
        }

        let evidence = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        evidence.name = "Result ad geometry: \(state)"
        evidence.lifetime = .keepAlways
        add(evidence)
    }

    func testResultLoadedAdDoesNotBlockExportOrPrivacy() {
        assertResultAdState("loaded")
    }

    func testResultNoFillAdDoesNotBlockExportOrPrivacy() {
        assertResultAdState("no-fill")
    }

    func testAdTrackingConsentRemainsReachableFromResult() {
        let app = launch("--qa-photo-fixture")
        XCTAssertTrue(app.buttons["Уменьшить фото"].waitForExistence(timeout: 8))
        app.buttons["Уменьшить фото"].tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))

        let privacy = app.buttons["ad-privacy-settings-button"]
        XCTAssertTrue(privacy.isHittable)
        privacy.tap()

        let decline = app.buttons["ad-consent-decline"]
        XCTAssertTrue(decline.waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["ad-consent-accept"].exists)
        XCTAssertTrue(decline.isHittable)
        decline.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["result-save-primary"].isHittable)
    }

    func testPhotoCompressionAndBackNavigation() {
        let app = launch("--qa-photo-fixture")
        let button = app.buttons["Уменьшить фото"]
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        XCTAssertTrue(button.isEnabled)
        button.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Сохранить файл"].exists)
        XCTAssertTrue(app.buttons["Поделиться"].exists)

        app.buttons["home-button"].tap()
        XCTAssertTrue(app.buttons["Уменьшить фото"].waitForExistence(timeout: 8))
    }

    /// Hermetic CI guard: verify that a synthetic PDF can be compressed and
    /// offers both export actions without presenting iOS Files-provider UI.
    /// The actual document browser/save sheet is tested separately on-device.
    func testPDFCompressionShowsExportActions() {
        let app = launch("--qa-pdf-fixture")
        let button = app.buttons["Уменьшить PDF"]
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        XCTAssertTrue(button.isEnabled)
        button.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))
        XCTAssertTrue(app.buttons["Сохранить файл"].exists)
        XCTAssertTrue(app.buttons["Поделиться"].exists)
    }

    /// Verify the Files import entry point independently of Apple's
    /// simulator-specific Files app accessibility tree and first-run state.
    func testFilesImportEntryPointAvailable() {
        let app = launch("--qa-photo-fixture")
        let button = app.buttons["import-files-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        XCTAssertTrue(button.isEnabled)
    }

    func testPDFCompressionAndSave() {
        let app = launch("--qa-pdf-fixture")
        let button = app.buttons["Уменьшить PDF"]
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        XCTAssertTrue(button.isEnabled)
        button.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 25))
        XCTAssertTrue(app.buttons["Сохранить файл"].exists)
        app.buttons["Сохранить файл"].tap()
        XCTAssertTrue(app.buttons["Сохранить"].waitForExistence(timeout: 10))
    }

    func testPixelAndDocumentModesWithPhotoFixture() {
        let app = launch("--qa-photo-fixture")
        let pixels = app.buttons["mode-pixels"]
        XCTAssertTrue(pixels.waitForExistence(timeout: 8))
        pixels.tap()
        XCTAssertTrue(app.buttons["Изменить размер"].waitForExistence(timeout: 8))
        app.buttons["mode-passport"].tap()
        XCTAssertTrue(app.buttons["Подготовить фото"].waitForExistence(timeout: 8))
    }

    func testFilesPickerOpensWithoutPriorFileInRecents() {
        let app = launch("--qa-photo-fixture")
        let button = app.buttons["import-files-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 8))
        button.tap()
        XCTAssertTrue(app.collectionViews["File View"].waitForExistence(timeout: 10))
    }
}
