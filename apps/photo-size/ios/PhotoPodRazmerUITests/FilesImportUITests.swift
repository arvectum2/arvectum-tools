import XCTest

final class FilesImportUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func resolveAdConsentIfNeeded(_ app: XCUIApplication) {
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 2) {
            decline.tap()
        }
    }

    private func launchAndImportFirstRecentFile() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        resolveAdConsentIfNeeded(app)

        let filesButton = app.buttons["import-files-button"]
        XCTAssertTrue(filesButton.waitForExistence(timeout: 8))
        filesButton.tap()

        let fileView = app.collectionViews["File View"]
        XCTAssertTrue(fileView.waitForExistence(timeout: 8))

        let firstFile = fileView.cells.firstMatch
        XCTAssertTrue(firstFile.waitForExistence(timeout: 8), "No image is available in Files Recents")
        firstFile.tap()
        return app
    }

    @discardableResult
    private func importAndProcessByWeight() throws -> XCUIApplication {
        let app = try launchAndImportFirstRecentFile()
        let processButton = app.buttons["Уменьшить фото"]
        XCTAssertTrue(processButton.waitForExistence(timeout: 8))
        XCTAssertTrue(processButton.isEnabled)
        processButton.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 20))
        return app
    }

    func testImportFromFilesAndProcess() throws {
        let app = try importAndProcessByWeight()
        XCTAssertTrue(app.buttons["Сохранить файл"].exists)
        XCTAssertTrue(app.buttons["edit-settings-button"].exists)
        XCTAssertTrue(app.buttons["home-button"].exists)
        XCTAssertFalse(app.buttons["Вернуться к настройкам"].exists)

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Files import processed on physical iPhone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSaveResultToFiles() throws {
        let app = try importAndProcessByWeight()

        app.buttons["Сохранить файл"].tap()
        let saveButton = app.buttons["Сохранить"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 8))
        saveButton.tap()

        let replaceButton = app.buttons["Заменить"]
        if replaceButton.waitForExistence(timeout: 2) {
            replaceButton.tap()
        }

        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 8))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Saved result returned to app"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testOpenShareUI() throws {
        let app = try importAndProcessByWeight()
        app.buttons["Поделиться"].tap()

        let sharingUI = XCUIApplication(bundleIdentifier: "com.apple.SharingUIService")
        XCTAssertTrue(sharingUI.wait(for: .runningForeground, timeout: 8))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "System share UI on physical iPhone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDocumentPrintSheetGenerated() throws {
        let app = XCUIApplication()
        app.launch()
        resolveAdConsentIfNeeded(app)

        app.buttons["На документы"].tap()

        let filesButton = app.buttons["import-files-button"]
        XCTAssertTrue(filesButton.waitForExistence(timeout: 8))
        filesButton.tap()

        let fileView = app.collectionViews["File View"]
        XCTAssertTrue(fileView.waitForExistence(timeout: 8))
        let firstFile = fileView.cells.firstMatch
        XCTAssertTrue(firstFile.waitForExistence(timeout: 8))
        firstFile.tap()

        let prepare = app.buttons["Подготовить фото"]
        XCTAssertTrue(prepare.waitForExistence(timeout: 8))
        prepare.tap()

        let cropConfirm = app.buttons["document-crop-confirm"]
        XCTAssertTrue(cropConfirm.waitForExistence(timeout: 8))
        cropConfirm.tap()

        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["Лист для печати"].waitForExistence(timeout: 8))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Document result with print sheet on physical iPhone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }




    func testExactResizeAndAdvancedToggle() throws {
        let app = XCUIApplication()
        app.launch()
        resolveAdConsentIfNeeded(app)

        app.buttons["По размеру"].tap()
        app.buttons["Точно W×H"].tap()

        let filesButton = app.buttons["import-files-button"]
        XCTAssertTrue(filesButton.waitForExistence(timeout: 8))
        filesButton.tap()

        let fileView = app.collectionViews["File View"]
        XCTAssertTrue(fileView.waitForExistence(timeout: 8))
        let firstFile = fileView.cells.firstMatch
        XCTAssertTrue(firstFile.waitForExistence(timeout: 8))
        firstFile.tap()

        let widthField = app.textFields["exact-width-field"]
        let heightField = app.textFields["exact-height-field"]
        XCTAssertTrue(widthField.waitForExistence(timeout: 8))
        widthField.tap()
        widthField.clearAndEnterText("600")
        XCTAssertTrue(heightField.waitForExistence(timeout: 8))
        XCTAssertFalse((heightField.value as? String ?? "").isEmpty)

        app.buttons["Дополнительно"].tap()
        let metadataToggle = app.switches["strip-metadata-toggle"]
        XCTAssertTrue(metadataToggle.waitForExistence(timeout: 8))
        XCTAssertEqual(metadataToggle.value as? String, "1")
        metadataToggle.tap()
        XCTAssertEqual(metadataToggle.value as? String, "0")
        metadataToggle.tap()
        XCTAssertEqual(metadataToggle.value as? String, "1")

        app.buttons["Изменить размер"].tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 20))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "Exact resize and metadata toggle on physical iPhone"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

private extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let current = value as? String else {
            typeText(text)
            return
        }
        if !current.isEmpty {
            tap()
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
            typeText(delete)
        }
        typeText(text)
    }

    func testBrowseFilesHierarchy() throws {
        let app = XCUIApplication()
        app.launch()
        let filesButton = app.buttons["import-files-button"]
        XCTAssertTrue(filesButton.waitForExistence(timeout: 8))
        filesButton.tap()
        let browse = app.buttons["Обзор"]
        XCTAssertTrue(browse.waitForExistence(timeout: 8))
        browse.tap()
        sleep(2)
        print("ARVECTUM_BROWSE_HIERARCHY_BEGIN")
        print(app.debugDescription)
        print("ARVECTUM_BROWSE_HIERARCHY_END")
    }

}
