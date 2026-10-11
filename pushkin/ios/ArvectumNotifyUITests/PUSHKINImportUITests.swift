import XCTest

final class PUSHKINImportUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testActuallyConfirm100Import() throws {
        let shortcuts = XCUIApplication(bundleIdentifier: "com.apple.shortcuts")
        shortcuts.activate()

        let adds = shortcuts.buttons.matching(
            NSPredicate(format: "label == %@", "Добавить")
        )
        XCTAssertGreaterThan(adds.count, 0)

        var tapped = false
        for i in 0..<adds.count {
            let b = adds.element(boundBy: i)
            print("ADD_BUTTON_\(i) exists=\(b.exists) hittable=\(b.isHittable) frame=\(b.frame)")
            if !tapped && b.exists && b.isHittable {
                b.tap()
                tapped = true
            }
        }
        XCTAssertTrue(tapped, "No hittable Add button")

        sleep(4)
        print("AFTER_REAL_ADD_BEGIN")
        print(shortcuts.debugDescription)
        print("AFTER_REAL_ADD_END")
    }
}
