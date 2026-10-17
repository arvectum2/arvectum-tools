import XCTest

/// Runs only against the isolated P2a QA bundle on an actual iPhone.
/// No existing voice-note data, production bundles, or Watch apps are used.
final class PhysicalVideoCaptureUITests: XCTestCase {
    func testShortTapStartsAndSavesAudio() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Physical iPhone microphone required")
        #else
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons["what.record.primary"]
        XCTAssertTrue(record.waitForExistence(timeout: 12))
        record.tap()
        let audioTitle = app.navigationBars.matching(NSPredicate(format:
            "identifier == %@ OR label == %@ OR identifier == %@ OR label == %@",
            "Новая запись", "Новая запись", "New recording", "New recording"
        )).firstMatch
        XCTAssertTrue(audioTitle.waitForExistence(timeout: 10),
                      "Short tap must start audio, never video")
        let stop = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save"
        )).firstMatch
        XCTAssertTrue(stop.waitForExistence(timeout: 20),
                      "Microphone must begin actual audio recording")
        Thread.sleep(forTimeInterval: 3)
        stop.tap()
        let closed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: audioTitle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 25), .completed,
                       "Audio capture must finish saving and dismiss")
        #endif
    }

    func testSavedVideosOpenPlayerAfterRelaunch() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Use an existing physically captured local MOV")
        #else
        let app = XCUIApplication()
        app.launch()
        let saved = app.buttons.matching(NSPredicate(format:
            "label BEGINSWITH %@ OR label BEGINSWITH %@", "Мои записи", "My recordings"
        )).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 12))
        saved.tap()
        let play = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Смотреть", "Play video"
        )).firstMatch
        XCTAssertTrue(play.waitForExistence(timeout: 15),
                      "Saved on-device videos must appear in Inbox after restart")
        play.tap()
        let close = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Закрыть", "Close"
        )).firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 12),
                      "The saved video must open in the local video player")
        close.tap()
        XCTAssertTrue(play.waitForExistence(timeout: 6),
                      "Closing the player must return to the saved recordings list")
        #endif
    }
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

        let videoTitle = app.navigationBars.matching(NSPredicate(format:
            "identifier == %@ OR identifier == %@ OR label == %@ OR label == %@",
            "Видеозаметка", "Video note", "Видеозаметка", "Video note"
        )).firstMatch
        XCTAssertTrue(videoTitle.waitForExistence(timeout: 10),
                      "Long press must open the video recorder, not audio")

        // Prefer the stable identifier, but log the actual accessibility tree
        // if a platform regression hides SwiftUI's camera control.
        let byID = app.buttons["what.video.switchCamera"]
        let byLabel = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@ OR label == %@ OR label == %@",
            "Переключить на фронтальную камеру", "Switch to front camera",
            "Переключить на основную камеру", "Switch to back camera"
        )).firstMatch
        let switchCamera = byID.waitForExistence(timeout: 8) ? byID : byLabel
        guard switchCamera.waitForExistence(timeout: 6) else {
            print("CAMERA_ACCESSIBILITY_TREE_BEGIN\n\(app.debugDescription)\nCAMERA_ACCESSIBILITY_TREE_END")
            let save = app.buttons.matching(NSPredicate(format:
                "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save"
            )).firstMatch
            if save.exists { save.tap() }
            XCTFail("Real video UI is present but camera switch control is not exposed")
            return
        }
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

        // The home control may EXIST behind a SwiftUI sheet while the MOV
        // exporter is still running. Do not terminate XCTest or the app until
        // the video recorder actually dismisses after durable import.
        let recorderClosed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: videoTitle
        )
        let completed = XCTWaiter.wait(for: [recorderClosed], timeout: 150)
        if completed != .completed {
            print("VIDEO_SAVE_TIMEOUT_HIERARCHY\n\(app.debugDescription)")
        }
        XCTAssertEqual(completed, .completed,
                       "MOV export + local repository import must finish before teardown")
        let homeVisible = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: record
        )
        XCTAssertEqual(XCTWaiter.wait(for: [homeVisible], timeout: 15), .completed,
                       "The capture button must be interactable after video save")
        #endif
    }
}
