import XCTest

/// QA-only Shortcuts handoff acceptance. Intentionally NEVER taps Add Shortcut,
/// Replace, Enable Automation, or touches existing user Shortcuts.
final class ShortcutPreviewSafetyUITests: XCTestCase {
    private let bundle = "ru.arvectum.tools.notify.physicalqa"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSignedBaseShortcutOpensNativePreviewWithoutImport() {
        let app = XCUIApplication(bundleIdentifier: bundle)
        app.launch()
        // If native preview fails to appear, still leave the phone in our
        // isolated QA app rather than exposing the user's Shortcuts library.
        defer { app.activate() }
        XCTAssertTrue(app.tabBars.buttons["Apps"].waitForExistence(timeout: 12))
        app.tabBars.buttons["Apps"].tap()

        let base = app.descendants(matching: .any)
            .matching(identifier: "setup-base-automation").firstMatch
        for _ in 0..<12 {
            if base.exists && base.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(base.exists && base.isHittable,
                      "QA app must surface its signed bundled shortcut")
        base.tap()

        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        if !shortcuts.wait(for: .runningForeground, timeout: 8) {
            // iOS may choose UIDocumentInteractionController instead of direct
            // open for a local .shortcut. Select only the Shortcuts app; never
            // press any import confirmation or alter existing automations.
            let openIn = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "Shortcuts"))
                .firstMatch
            if openIn.waitForExistence(timeout: 5) && openIn.isHittable {
                openIn.tap()
            }
        }
        XCTAssertTrue(shortcuts.wait(for: .runningForeground, timeout: 10),
                      "iOS must present the signed file to Apple Shortcuts")
        let preview = shortcuts.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            "Add Shortcut", "Добавить"
        )).firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 12),
                      "Signed shortcut must reach the native pre-import preview")

        // Deliberately DO NOT tap Add / Replace / Enable. Return to the QA
        // app to leave the user's real Shortcuts library untouched.
        app.activate()
        XCTAssertTrue(app.tabBars.buttons["Apps"].waitForExistence(timeout: 10))
    }
}
