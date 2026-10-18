import XCTest
import SwiftUI
@testable import ArvectumCore

final class AdaptiveLayoutTests: XCTestCase {
    func testCompactAndExpandedContainerBehaviors() {
        XCTAssertFalse(ArvectumAdaptiveMetrics(availableWidth: 430)
            .canShowTwoPanes(horizontalInset: 0))
        XCTAssertFalse(ArvectumAdaptiveMetrics(availableWidth: 659)
            .canShowTwoPanes(horizontalInset: 0))
        XCTAssertTrue(ArvectumAdaptiveMetrics(availableWidth: 660)
            .canShowTwoPanes(horizontalInset: 0))
        XCTAssertTrue(ArvectumAdaptiveMetrics(availableWidth: 930)
            .canShowTwoPanes())
    }

    func testDuoFoldAndUnfoldUseWindowWidthNotDeviceIdentity() {
        let folded = ArvectumAdaptiveMetrics(availableWidth: 410)
        let unfolded = ArvectumAdaptiveMetrics(availableWidth: 860)
        XCTAssertFalse(folded.canShowTwoPanes())
        XCTAssertTrue(unfolded.canShowTwoPanes())
    }

    func testAccessibilityTypographyForcesOnePane() {
        XCTAssertFalse(ArvectumAdaptiveMetrics(
            availableWidth: 1366, accessibilityText: true
        ).canShowTwoPanes())
    }

    func testConfigurablePaneWidthAndGutters() {
        let space = ArvectumAdaptiveMetrics(availableWidth: 820)
        XCTAssertTrue(space.canShowTwoPanes(minimumPaneWidth: 340))
        XCTAssertFalse(space.canShowTwoPanes(
            minimumPaneWidth: 400, spacing: 24, horizontalInset: 20
        ))
    }

    func testInvalidMeasurementsAreSafe() {
        for width: CGFloat in [-100, 0, .infinity, -.infinity, .nan] {
            let metrics = ArvectumAdaptiveMetrics(availableWidth: width)
            XCTAssertFalse(metrics.canShowTwoPanes())
            XCTAssertEqual(metrics.readableWidth(maxWidth: 760), 0)
        }
    }

    func testReadableWidthNeverOverflowsContainer() {
        XCTAssertEqual(ArvectumAdaptiveMetrics(availableWidth: 390)
            .readableWidth(maxWidth: 760), 390)
        XCTAssertEqual(ArvectumAdaptiveMetrics(availableWidth: 1200)
            .readableWidth(maxWidth: 760), 760)
    }

    @MainActor func testSharedViewPrimitivesConstruct() {
        let column = ArvectumReadableColumn { Text("Sample") }
        let split = ArvectumAdaptiveContentStack(
            leading: { Text("Left") },
            trailing: { Text("Right") }
        )
        _ = column
        _ = split
    }
}
