import Foundation
import XCTest
@testable import WhatIOS

/// Regression gate: two different UhWhat? QA apps must not steal each other's
/// Watch-face deep links or use one another's bundle identifiers.
final class WatchPackagingIsolationTests: XCTestCase {
    func testEmbeddedWatchAndComplicationBelongOnlyToP2aQA() throws {
        let host = Bundle.main
        XCTAssertEqual(host.bundleIdentifier, "ru.arvectum.tools.what.p2aqa")
        let watchPath = host.bundleURL.appendingPathComponent("Watch/WhatWatch.app")
        XCTAssertTrue(FileManager.default.fileExists(atPath: watchPath.path),
                      "The Watch app must be embedded in the iPhone QA package")
        let watch = try XCTUnwrap(Bundle(url: watchPath))
        XCTAssertEqual(watch.bundleIdentifier, "ru.arvectum.tools.what.p2aqa.watch")
        XCTAssertEqual(watch.object(forInfoDictionaryKey: "WKCompanionAppBundleIdentifier") as? String,
                       host.bundleIdentifier)

        let urlTypes = try XCTUnwrap(watch.object(forInfoDictionaryKey: "CFBundleURLTypes")
            as? [[String: Any]])
        let schemes = urlTypes.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        XCTAssertEqual(schemes, [WatchCaptureRouting.scheme])
        XCTAssertEqual(WatchCaptureRouting.captureURL.absoluteString,
                       "whatp2aqa://capture")
        XCTAssertFalse(schemes.contains("what"))
        XCTAssertFalse(schemes.contains("whatqa"))

        let complicationPath = watchPath.appendingPathComponent(
            "PlugIns/WhatWatchComplication.appex"
        )
        let complication = try XCTUnwrap(Bundle(url: complicationPath))
        XCTAssertEqual(complication.bundleIdentifier,
                       "ru.arvectum.tools.what.p2aqa.watch.capturewidget")
        let label = try XCTUnwrap(complication.object(
            forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        XCTAssertTrue(label.contains("P2a QA"),
                      "The QA complication must have a distinct localized name: \(label)")
    }
}
