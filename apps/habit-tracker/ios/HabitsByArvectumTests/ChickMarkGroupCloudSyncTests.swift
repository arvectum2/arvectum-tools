import XCTest
@testable import HabitsByArvectum

final class ChickMarkGroupCloudSyncTests: XCTestCase {
    private let old = Date(timeIntervalSince1970: 1_000)
    private let recent = Date(timeIntervalSince1970: 2_000)

    func testConcurrentDifferentGroupCreationsAreMerged() {
        let groupA = UUID()
        let groupB = UUID()
        let first = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [],
            to: [ChickMarkGroup(id: groupA, name: "Home", habitIDs: [])],
            at: old, author: "iphone"
        )
        let second = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [],
            to: [ChickMarkGroup(id: groupB, name: "Fitness", habitIDs: [])],
            at: old, author: "simulator"
        )
        XCTAssertEqual(first.joined(with: second).materialize().count, 2)
        XCTAssertEqual(first.joined(with: second), second.joined(with: first))
    }

    func testDeletionTombstoneBeatsOlderOfflineSnapshot() {
        let id = UUID()
        let created = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [], to: [ChickMarkGroup(id: id, name: "Reading", habitIDs: [])],
            at: old, author: "phone"
        )
        let deleted = created.applyingLocalChange(
            from: [ChickMarkGroup(id: id, name: "Reading", habitIDs: [])],
            to: [], at: recent, author: "phone"
        )
        XCTAssertTrue(deleted.joined(with: created).materialize().isEmpty)
        XCTAssertTrue(created.joined(with: deleted).materialize().isEmpty)
    }

    func testMembershipMovesBetweenGroupsConvergeToLatestChange() {
        let habit = UUID()
        let a = ChickMarkGroup(id: UUID(), name: "Health", habitIDs: [habit])
        let b = ChickMarkGroup(id: UUID(), name: "Work", habitIDs: [])
        let initial = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [], to: [a, b], at: old, author: "deviceA"
        )
        let revisedA = ChickMarkGroup(id: a.id, name: a.name, habitIDs: [])
        let revisedB = ChickMarkGroup(id: b.id, name: b.name, habitIDs: [habit])
        let moved = initial.applyingLocalChange(
            from: [a, b], to: [revisedA, revisedB],
            at: recent, author: "deviceB"
        )
        let converged = initial.joined(with: moved).materialize()
        XCTAssertEqual(
            converged.first(where: { $0.id == b.id })?.habitIDs,
            [habit]
        )
        XCTAssertTrue(
            converged.first(where: { $0.id == a.id })?.habitIDs.isEmpty == true
        )
    }

    func testCloudRecordEncodingRoundTrip() throws {
        let groups = [ChickMarkGroup(
            id: UUID(), name: "Work",
            habitIDs: [UUID(), UUID()]
        )]
        let original = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [], to: groups, at: old, author: "test"
        )
        let restored = try JSONDecoder().decode(
            ChickMarkGroupCloudSnapshot.self,
            from: JSONEncoder().encode(original)
        )
        XCTAssertEqual(restored, original)
        XCTAssertEqual(
            Set(restored.materialize()[0].habitIDs),
            Set(groups[0].habitIDs)
        )
        XCTAssertEqual(restored.materialize()[0].name, groups[0].name)
    }
}
