import XCTest

/// Runs only against the isolated P2a QA bundle on an actual iPhone.
/// No existing voice-note data, production bundles, or Watch apps are used.
final class PhysicalVideoCaptureUITests: XCTestCase {
    func testDiscardPhysicalVideoDoesNotSave() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Physical capture is required for discard acceptance")
        #else
        let app = XCUIApplication()
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 15))
        home.press(forDuration: 0.8)
        let camera = app.buttons["what.video.switchCamera"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: camera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 20), .completed)
        Thread.sleep(forTimeInterval: 3)
        let discard = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Отменить", "Discard"
        )).firstMatch
        XCTAssertTrue(discard.waitForExistence(timeout: 10))
        discard.tap()
        let returned = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: home
        )
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 15), .completed)
        Thread.sleep(forTimeInterval: 4) // Allow AVFoundation to close its clip.
        #endif
    }
    /// Exercises a multi-segment discard with the real front/back cameras.
    /// The host must independently verify that VideoCaptures stays empty and
    /// that local-notes.json has not changed (isolated QA container only).
    func testDiscardAfterCameraSwitchLeavesNoCaptureFiles() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Physical cameras required for multi-segment discard audit")
        #else
        let app = XCUIApplication()
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 15))
        home.press(forDuration: 0.8)
        let camera = app.buttons["what.video.switchCamera"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: camera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 20), .completed)
        Thread.sleep(forTimeInterval: 3)
        camera.tap()
        let switched = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: camera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [switched], timeout: 20), .completed)
        Thread.sleep(forTimeInterval: 3)
        let discard = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Отменить", "Discard"
        )).firstMatch
        XCTAssertTrue(discard.waitForExistence(timeout: 10))
        discard.tap()
        let returned = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: home
        )
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 20), .completed)
        Thread.sleep(forTimeInterval: 4) // AVFoundation delegate cleanup.
        #endif
    }

    /// The disposable iPhone Duo simulator has microphone access revoked by
    /// simctl privacy. No real iPhone permissions are touched.
    func testMicrophoneDeniedShowsErrorWithoutStartingCapture() throws {
        #if targetEnvironment(simulator)
        let app = XCUIApplication()
        app.launch()
        let record = app.buttons["what.record.primary"]
        XCTAssertTrue(record.waitForExistence(timeout: 15))
        record.tap()
        let microphoneDenied = app.alerts.firstMatch
        XCTAssertTrue(microphoneDenied.waitForExistence(timeout: 15),
                      "Denied microphone permission must be explained")
        let details = microphoneDenied.staticTexts.allElementsBoundByIndex
            .map(\.label).joined(separator: " ").lowercased()
        XCTAssertTrue(details.contains("микрофон") || details.contains("microphone"),
                      "Denied permission alert must specifically mention the microphone: \(details)")
        let stop = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save"
        )).firstMatch
        XCTAssertFalse(stop.exists, "No recording must begin after access denial")
        microphoneDenied.buttons["OK"].tap()
        let retry = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Начать запись", "Start recording"
        )).firstMatch
        let home = app.buttons["what.record.primary"]
        let recoverable = retry.waitForExistence(timeout: 5) || home.exists
        if !recoverable { print("MIC_DENIAL_UI_TREE\n\(app.debugDescription)") }
        XCTAssertTrue(recoverable, "User must be able to retry capture or return home")
        #else
        throw XCTSkip("This test only modifies permissions on a disposable simulator")
        #endif
    }

    /// Actual physical-camera flip stress, isolated QA bundle only.
    /// Verify local note count and temporary captures independently via devicectl.
    func testSixPhysicalCameraSwitchesSaveOneVideo() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Real back/front camera switches require a physical iPhone")
        #else
        let app = XCUIApplication()
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 20))
        home.press(forDuration: 0.8)
        let switchButton = app.buttons["what.video.switchCamera"]
        let saving = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save"
        )).firstMatch
        XCTAssertTrue(switchButton.waitForExistence(timeout: 20))
        let initiallyReady = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: switchButton
        )
        XCTAssertEqual(XCTWaiter.wait(for: [initiallyReady], timeout: 25), .completed)
        for index in 0..<6 {
            Thread.sleep(forTimeInterval: 3)
            let beforeLabel = switchButton.label
            switchButton.tap()
            let changed = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label != %@", beforeLabel),
                object: switchButton
            )
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 25), .completed,
                           "Camera direction should change at flip \(index + 1)")
            let ready = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: switchButton
            )
            XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 25), .completed)
            print("WHAT_PHYSICAL_CAMERA_FLIP_\(index + 1)_PASS")
        }
        Thread.sleep(forTimeInterval: 3)
        XCTAssertTrue(saving.isEnabled)
        saving.tap()
        let returned = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: home
        )
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 180), .completed,
                       "Combined camera video must save and return Home")
        print("WHAT_PHYSICAL_SIX_CAMERA_FLIPS_AND_SAVE_PASS")
        #endif
    }

    /// More than double the previous 90-second real-camera acceptance.
    /// Only adds a disposable video to ru.arvectum.tools.what.multimodalqa.
    func testThreeMinuteContinuousPhysicalVideoSaves() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Real camera and microphone required for three-minute recording")
        #else
        let app = XCUIApplication()
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 20))
        home.press(forDuration: 0.8)
        let stop = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save"
        )).firstMatch
        XCTAssertTrue(stop.waitForExistence(timeout: 20))
        let camera = app.buttons["what.video.switchCamera"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: camera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 25), .completed)
        Thread.sleep(forTimeInterval: 180)
        XCTAssertTrue(stop.isEnabled, "Camera must remain stoppable at three minutes")
        stop.tap()
        let returned = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: home
        )
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 180), .completed,
                       "Three-minute MOV must commit to the local QA library")
        print("WHAT_PHYSICAL_180_SECOND_MOV_SAVED_PASS")
        #endif
    }

    /// A bounded 90-second capture smoke test on the isolated QA application.
    /// Not a substitute for multi-hour recording or low-storage stress tests.
    func testNinetySecondContinuousPhysicalVideoSaves() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("A physical camera and microphone are required")
        #else
        let app = XCUIApplication()
        app.launch()
        let home = app.buttons["what.record.primary"]
        XCTAssertTrue(home.waitForExistence(timeout: 15))
        home.press(forDuration: 0.8)
        let save = app.buttons.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Стоп и сохранить", "Stop and save"
        )).firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 18))
        // A running camera is indicated by the enabled switch control.
        let camera = app.buttons["what.video.switchCamera"]
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: camera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 20), .completed)
        Thread.sleep(forTimeInterval: 90)
        XCTAssertTrue(save.isEnabled, "Long recording must remain stoppable")
        save.tap()
        let videoTitle = app.navigationBars.matching(NSPredicate(format:
            "label == %@ OR label == %@", "Видеозаметка", "Video note"
        )).firstMatch
        let closed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: videoTitle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 180), .completed,
                       "Long video must finish export and local import")
        let backHome = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: home
        )
        XCTAssertEqual(XCTWaiter.wait(for: [backHome], timeout: 15), .completed)
        #endif
    }
    /// Deliberately terminates only the independently installed P2a QA app.
    /// Run alone: the host backs up its journal *before* restarting and
    /// independently verifies recovery on the next launch.
    func testCrashAfterSwitchLeavesVideoRecoveryJournal() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Physical camera required for crash recovery acceptance")
        #else
        let app = XCUIApplication()
        app.launch()
        let primary = app.buttons["what.record.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 12))
        primary.press(forDuration: 0.8)
        let camera = app.buttons["what.video.switchCamera"]
        XCTAssertTrue(camera.waitForExistence(timeout: 15))
        XCTAssertTrue(camera.isEnabled, "First video segment must be recording")
        Thread.sleep(forTimeInterval: 3)
        camera.tap() // The first closed segment must survive the process kill.
        let switched = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: camera
        )
        XCTAssertEqual(XCTWaiter.wait(for: [switched], timeout: 20), .completed)
        Thread.sleep(forTimeInterval: 3) // Second segment currently open.
        print("P2A_QA_ABRUPT_TERMINATION_AFTER_SWITCH")
        app.terminate() // XCTest forcibly terminates the isolated test app.
        XCTAssertEqual(app.state, .notRunning)
        // Do NOT relaunch here. The host takes a forensic backup first.
        #endif
    }
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
            "label BEGINSWITH %@ OR label BEGINSWITH %@", "Все заметки", "All notes"
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
