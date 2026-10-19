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
        XCTAssertLessThanOrEqual(
            save.frame.maxY, app.frame.maxY + 1,
            "Save cannot fall below the visible viewport"
        )
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
        let pixels = app.buttons["По размеру"]
        XCTAssertTrue(pixels.waitForExistence(timeout: 8))
        pixels.tap()
        XCTAssertTrue(app.buttons["Изменить размер"].waitForExistence(timeout: 8))
        app.buttons["На документы"].tap()
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
