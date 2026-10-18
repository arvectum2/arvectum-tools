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
        // FileProvider uses a non-breaking space in the Russian sidebar
        // label ("На iPhone"), so never match the full label literally.
        // Navigate into the local device location first; the first picker
        // screen may be Recents or the root Browse list.
        let localLocation = app.cells.matching(NSPredicate(
            format: "identifier CONTAINS %@ AND label CONTAINS[c] %@",
                    "DOC.sidebar.item.", "iPhone"
        )).firstMatch
        if !localLocation.waitForExistence(timeout: 5) {
            let browse = app.buttons.matching(NSPredicate(
                format: "label == %@ OR label == %@", "Обзор", "Browse"
            )).firstMatch
            if browse.waitForExistence(timeout: 4) { browse.tap() }
        }
        XCTAssertTrue(localLocation.waitForExistence(timeout: 10),
            "Must first open local device location; never select from Recents")
        localLocation.tap()
        let folder = app.staticTexts.matching(NSPredicate(
            format: "label == %@ OR label == %@",
                   "Photo PDF QA", "Фото PDF QA"
        )).firstMatch
        let foundQAOnlyFolder = folder.waitForExistence(timeout: 12)
        if !foundQAOnlyFolder {
            print("FILES_PICKER_QA_TREE_BEGIN")
            print(app.debugDescription)
            print("FILES_PICKER_QA_TREE_END")
        }
        XCTAssertTrue(foundQAOnlyFolder,
            "Only the seeded Photo PDF QA folder may be selected")
        folder.tap()

        // Select the actual UIDocumentPicker file cell, not the nested
        // filename label: the latter can receive a tap without confirming
        // the document import on iPadOS 27.
        let fixture = app.cells.matching(NSPredicate(
            format: "identifier == %@", "ARVECTUM_QA_INPUT, pdf"
        )).firstMatch
        XCTAssertTrue(fixture.waitForExistence(timeout: 12),
            "Only the exact seeded ARVECTUM_QA_INPUT.pdf cell is allowed")
        fixture.tap()

        // The selected-file text is merged into a SwiftUI button on some
        // iOS 27 accessibility trees. Instead, require the actual action to
        // transition from disabled -> enabled after the exact QA PDF import.
        let compress = app.buttons["Уменьшить PDF"]
        XCTAssertTrue(compress.waitForExistence(timeout: 10))
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: compress
        )
        let imported = XCTWaiter.wait(for: [ready], timeout: 10)
        if imported != .completed {
            print("QA_IMPORT_FAILURE_HIERARCHY_BEGIN")
            print(app.debugDescription)
            print("QA_IMPORT_FAILURE_HIERARCHY_END")
        }
        XCTAssertEqual(imported, .completed,
                       "Synthetic PDF was not imported and made compressible")
        compress.tap()
        XCTAssertTrue(app.staticTexts["ГОТОВО"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.buttons["Сохранить файл"].exists)
    }
}
