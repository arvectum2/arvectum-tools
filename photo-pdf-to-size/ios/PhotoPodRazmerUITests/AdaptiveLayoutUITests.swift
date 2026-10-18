import XCTest

/// Tests UI resilience on isolated iPad/Duo simulators, without importing
/// real Files/Photos documents or mutating on-device user data.
final class AdaptiveLayoutUITests: XCTestCase {
    func testTaskRemainsAvailableAfterOrientationChange() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ARVECTUM_NATIVE_QA_FIXTURE"] = "no-fill"
        app.launch()
        let decline = app.buttons["ad-consent-decline"]
        if decline.waitForExistence(timeout: 3) {
            decline.tap()
        }

        let task = app.descendants(matching: .any)["main-task-card"]
        XCTAssertTrue(task.waitForExistence(timeout: 15))
        XCTAssertTrue(app.descendants(matching: .any)["app-footer"].exists)
        // A wide container shows the additional read-only preview;
        // a compact Duo outer screen retains the primary workflow alone.
        let placeholder = app.descendants(matching: .any)["adaptive-source-placeholder"]
        if app.frame.width > 760 {
            XCTAssertTrue(placeholder.waitForExistence(timeout: 8))
        }
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(task.waitForExistence(timeout: 10),
                      "The current task cannot disappear after resizing.")
        XCTAssertTrue(app.descendants(matching: .any)["app-footer"].exists)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(task.waitForExistence(timeout: 10))
    }
}
