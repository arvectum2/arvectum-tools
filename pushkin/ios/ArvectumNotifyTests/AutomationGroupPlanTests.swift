import XCTest
@testable import ArvectumNotify

final class AutomationGroupPlanTests: XCTestCase {
    func testGroupBoundariesZeroOneTwentyFiveTwentySixAndFiftyOne() {
        XCTAssertTrue(AutomationGroupPlan.groups([Int]()).isEmpty)
        XCTAssertEqual(AutomationGroupPlan.groups([0]).map(\.count), [1])
        XCTAssertEqual(AutomationGroupPlan.groups(Array(0..<25)).map(\.count), [25])
        XCTAssertEqual(AutomationGroupPlan.groups(Array(0..<26)).map(\.count), [25, 1])
        XCTAssertEqual(AutomationGroupPlan.groups(Array(0..<51)).map(\.count), [25, 25, 1])
    }

    func testGroupingPreservesSelectedOrderAndHasNoDroppedApps() {
        let chosen = Array(1...70)
        let grouped = AutomationGroupPlan.groups(chosen)
        XCTAssertEqual(grouped.flatMap { $0 }, chosen)
        XCTAssertTrue(grouped.allSatisfy { $0.count <= 25 })
        XCTAssertEqual(grouped.count, 3)
    }

    func testToggleIsReversibleAndNoDuplicateBundleIDs() {
        let once = AutomationGroupPlan.toggle("com.example.a", in: [])
        XCTAssertEqual(once, ["com.example.a"])
        let twice = AutomationGroupPlan.toggle("com.example.a", in: once)
        XCTAssertEqual(twice, [])
        let withDuplicates = AutomationGroupPlan.toggle(
            "com.example.b",
            in: ["com.example.a", "com.example.a"]
        )
        XCTAssertEqual(withDuplicates, ["com.example.a", "com.example.b"])
        XCTAssertEqual(
            AutomationGroupPlan.toggle("com.example.b", in: withDuplicates),
            ["com.example.a"]
        )
    }

    func testPersistenceIsLocalDeterministicAndSanitizesCorruptData() {
        let ids = ["com.telegram", "com.whatsapp", "com.telegram", ""]
        let saved = AutomationGroupPlan.encode(ids)
        XCTAssertEqual(
            AutomationGroupPlan.decode(saved),
            ["com.telegram", "com.whatsapp"]
        )
        XCTAssertEqual(AutomationGroupPlan.decode("not valid json"), [])
        XCTAssertEqual(AutomationGroupPlan.decode(""), [])
    }

    func testOptionalPlannerUsesCatalogWithoutAssumingInstalledApps() {
        XCTAssertEqual(AutomationGroupPlan.suggestedGroupSize, 25)
        XCTAssertEqual(CoverageCatalog.entries.count, 1000)
        XCTAssertTrue(CoverageCatalog.entries.allSatisfy { !$0.bundleIdentifier.isEmpty })
    }
}
