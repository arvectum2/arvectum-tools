import XCTest

/// Runs only against the isolated P2a QA bundle on an actual iPhone.
/// No existing voice-note data, production bundles, or Watch apps are used.
final class PhysicalVideoCaptureUITests: XCTestCase {
    func testHoldSwitchCameraAndSaveLocalMovie() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("A real camera and microphone are required")
        #else
        let app = XCUIApplication()
        app.launch()

        let record = app.buttons["what.record.primary"]
        XCTAssertTrue(record.waitForExistence(timeout: 12))
        record.press(forDuration: 0.8)

        // On first use, the iOS camera and microphone privacy prompts may
        // appear in sequence. Never change permissions for the other QA app.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for _ in 0..<2 {
            let prompt = springboard.alerts.firstMatch
            guard prompt.waitForExistence(timeout: 8) else { break }
            let allow = prompt.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@ OR label == %@",
                "Allow", "OK", "Разрешить", "Разрешить при использовании приложения",
                "Allow While Using App", "Allow Access")
            ).firstMatch
            XCTAssertTrue(allow.exists, "Explicit camera/microphone access must be granted for this QA app")
            allow.tap()
        }

        let switchCamera = app.buttons["what.video.switchCamera"]
        XCTAssertTrue(switchCamera.waitForExistence(timeout: 20),
                      "Long press must open the real camera recording UI")
        let videoReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: switchCamera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [videoReady], timeout: 20), .completed,
                       "Both cameras and the microphone should be recording")
        Thread.sleep(forTimeInterval: 2)
        switchCamera.tap()

        let secondSegmentReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"),
            object: switchCamera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [secondSegmentReady], timeout: 20), .completed,
                       "Recording must resume on the other camera")
        Thread.sleep(forTimeInterval: 2)

        let save = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save")
        ).firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        save.tap()
        XCTAssertTrue(record.waitForExistence(timeout: 35),
                      "After saving video, return to home; media integrity is checked on host")
        #endif
    }
}
