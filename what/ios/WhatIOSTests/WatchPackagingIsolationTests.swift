import Foundation
import XCTest
@testable import WhatIOS

/// Production release gate: the public iPhone/Watch/Widget IDs must match
/// the published app so App Store upgrades preserve Watch recordings.
final class WatchPackagingIsolationTests: XCTestCase {
    func testEmbeddedWatchAndComplicationUseProductionIdentity() throws {
        let host = Bundle.main
        XCTAssertEqual(host.bundleIdentifier, "ru.arvectum.tools.what")
        let watchPath = host.bundleURL.appendingPathComponent("Watch/WhatWatch.app")
        XCTAssertTrue(FileManager.default.fileExists(atPath: watchPath.path),
                      "The production iPhone app must embed its Watch companion")
        let watch = try XCTUnwrap(Bundle(url: watchPath))
        XCTAssertEqual(watch.bundleIdentifier, "ru.arvectum.tools.what.watch")
        XCTAssertEqual(watch.object(forInfoDictionaryKey: "WKCompanionAppBundleIdentifier") as? String,
                       host.bundleIdentifier)

        let urlTypes = try XCTUnwrap(watch.object(forInfoDictionaryKey: "CFBundleURLTypes")
            as? [[String: Any]])
        let schemes = urlTypes.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        XCTAssertEqual(schemes, [WatchCaptureRouting.scheme])
        XCTAssertEqual(WatchCaptureRouting.captureURL.absoluteString,
                       "what://capture")
        XCTAssertTrue(schemes.contains("what"))
        XCTAssertFalse(schemes.contains("whatp2aqa"))
        XCTAssertFalse(schemes.contains("whatqa"))

        let complicationPath = watchPath.appendingPathComponent(
            "PlugIns/WhatWatchComplication.appex"
        )
        let complication = try XCTUnwrap(Bundle(url: complicationPath))
        XCTAssertEqual(complication.bundleIdentifier,
                       "ru.arvectum.tools.what.watch.capturewidget")
        let label = try XCTUnwrap(complication.object(
            forInfoDictionaryKey: "CFBundleDisplayName") as? String)
        XCTAssertFalse(label.contains("QA"),
                       "Production Watch complication cannot display QA branding: \(label)")
    }
}
