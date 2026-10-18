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
            format: "identifier CONTAINS %@ AND (label CONTAINS[c] %@ OR label CONTAINS[c] %@)",
                    "DOC.sidebar.item.", "iPhone", "iPad"
        )).firstMatch
        if !localLocation.waitForExistence(timeout: 5) {
            let browse = app.buttons.matching(NSPredicate(
                format: "label == %@ OR label == %@", "Обзор", "Browse"
            )).firstMatch
            if browse.waitForExistence(timeout: 4) { browse.tap() }
        }
        let hasLocalLocation = localLocation.waitForExistence(timeout: 10)
        if !hasLocalLocation {
            print("QA_IPAD_FILEPICKER_TREE_BEGIN")
            print(app.debugDescription)
            print("QA_IPAD_FILEPICKER_TREE_END")
        }
        if hasLocalLocation {
            localLocation.tap()
        } else {
            // iPhone iOS 27 sometimes restores Files already positioned at
            // On My iPhone. Its navigation title is nonbreaking-space aware,
            // and the QA directory still must be selected by exact name.
            let alreadyLocal = app.navigationBars.staticTexts.matching(
                NSPredicate(format:
                    "label CONTAINS[c] %@ AND (label CONTAINS[c] %@ OR label CONTAINS[c] %@)",
                    "На", "iPhone", "iPad")
            ).firstMatch
            XCTAssertTrue(alreadyLocal.waitForExistence(timeout: 7),
                "Must be in a local-device location before selecting QA file")
        }
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
        let export = app.buttons["Сохранить файл"]
        XCTAssertTrue(export.exists)
        export.tap()
        // FileExporter can initially show a saved destination or browse root.
        // Never approve a save outside the exact QA-owned folder.
        let qaDestination = app.buttons.matching(NSPredicate(
            format: "(label CONTAINS %@ OR label CONTAINS %@) AND label CONTAINS %@",
                   "Photo PDF QA", "Фото PDF QA", "Меню действий"
        )).firstMatch
        let destinationVisible = qaDestination.waitForExistence(timeout: 10)
        if !destinationVisible {
            print("QA_EXPORT_DESTINATION_TREE_BEGIN")
            print(app.debugDescription)
            print("QA_EXPORT_DESTINATION_TREE_END")
        }
        XCTAssertTrue(destinationVisible,
            "System exporter's current path must be exact Photo PDF QA folder")
        // The true system Save action has a stable FileProvider identifier;
        // never tap a generic button or approve an arbitrary destination.
        let save = app.buttons.matching(NSPredicate(
            format: "identifier == %@ AND label == %@",
                   "DOCPicker.actionButton", "Сохранить"
        )).firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isEnabled)
        save.tap()
        let done = app.staticTexts["ГОТОВО"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 10))

        // Close the round trip by opening ONLY the known output file through
        // the same system Files importer. This catches a silent save failure
        // despite the exporter dismissing successfully.
        app.buttons["home-button"].tap()
        let pdfMode = app.buttons["PDF"]
        XCTAssertTrue(pdfMode.waitForExistence(timeout: 8))
        pdfMode.tap()
        let chooseAgain = app.buttons.matching(NSPredicate(
            format: "label CONTAINS %@ OR label CONTAINS %@",
                    "Выбрать PDF", "PDF выбран"
        )).firstMatch
        XCTAssertTrue(chooseAgain.waitForExistence(timeout: 8))
        chooseAgain.tap()
        let exportedFile = app.cells.matching(NSPredicate(
            format: "identifier == %@", "pdf-do-razmera, pdf"
        )).firstMatch
        if !exportedFile.waitForExistence(timeout: 6) {
            let browse = app.buttons.matching(NSPredicate(
                format: "label == %@ OR label == %@", "Обзор", "Browse"
            )).firstMatch
            if browse.waitForExistence(timeout: 3) { browse.tap() }
            let local = app.cells.matching(NSPredicate(
                format: "identifier CONTAINS %@ AND (label CONTAINS[c] %@ OR label CONTAINS[c] %@)",
                       "DOC.sidebar.item.", "iPhone", "iPad"
            )).firstMatch
            XCTAssertTrue(local.waitForExistence(timeout: 8))
            local.tap()
            let qaFolder = app.staticTexts.matching(NSPredicate(
                format: "label == %@ OR label == %@", "Photo PDF QA", "Фото PDF QA"
            )).firstMatch
            XCTAssertTrue(qaFolder.waitForExistence(timeout: 8))
            qaFolder.tap()
        }
        XCTAssertTrue(exportedFile.waitForExistence(timeout: 10),
            "The saved QA PDF must appear in the system Files picker")
        exportedFile.tap()
        let compressAgain = app.buttons["Уменьшить PDF"]
        XCTAssertTrue(compressAgain.waitForExistence(timeout: 8))
        let readyAgain = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: compressAgain
        )
        XCTAssertEqual(XCTWaiter.wait(for: [readyAgain], timeout: 10), .completed,
            "Reopening the exported PDF must succeed without touching personal files")
    }
}
