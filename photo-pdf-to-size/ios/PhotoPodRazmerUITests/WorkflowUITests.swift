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
