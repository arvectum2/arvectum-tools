import XCTest

/// Safe iPhone Files acceptance: selects ONLY an exact synthetic filename
/// seeded in the separate Photo PDF QA app container by devicectl.
final class PhysicalQAFilePickerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testImportSyntheticPDFViaPhysicalFilesPickerAndCompress() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU"
        ]
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 3) { decline.tap() }
        XCTAssertTrue(app.buttons["PDF"].waitForExistence(timeout: 12))
        app.buttons["PDF"].tap()

        let selectPDF = app.buttons.matching(NSPredicate(
            format: "label CONTAINS %@", "Выбрать PDF"
        )).firstMatch
        XCTAssertTrue(selectPDF.waitForExistence(timeout: 10))
        selectPDF.tap()

        // Do not tap any item in Recents: it may contain private user files.
        // Navigate specifically into the dedicated QA app folder.
        let browse = app.buttons["Обзор"]
        if browse.waitForExistence(timeout: 5) { browse.tap() }
        let onPhone = app.staticTexts["На iPhone"].firstMatch
        if onPhone.waitForExistence(timeout: 7) { onPhone.tap() }
        let folder = app.staticTexts["Photo PDF QA"].firstMatch
        XCTAssertTrue(folder.waitForExistence(timeout: 12),
            "Only the seeded Photo PDF QA folder may be selected")
        folder.tap()

        let fixture = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS %@", "ARVECTUM_QA_INPUT"
        )).firstMatch
        XCTAssertTrue(fixture.waitForExistence(timeout: 12),
            "Only ARVECTUM_QA_INPUT.pdf is allowed")
        fixture.tap()

        XCTAssertTrue(app.staticTexts["PDF выбран"].firstMatch
            .waitForExistence(timeout: 10), "Did not import seeded PDF")
        let compress = app.buttons["Уменьшить PDF"]
        XCTAssertTrue(compress.waitForExistence(timeout: 10))
        XCTAssertTrue(compress.isEnabled)
        compress.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["Сохранить файл"].exists)
    }
}
