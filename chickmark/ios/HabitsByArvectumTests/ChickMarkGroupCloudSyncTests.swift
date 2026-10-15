import XCTest
@testable import HabitsByArvectum

final class ChickMarkGroupCloudSyncTests: XCTestCase {
    private let old = Date(timeIntervalSince1970: 1_000)
    private let recent = Date(timeIntervalSince1970: 2_000)

    func testDuplicatedCloudRecordsCannotCrashAndTombstonesWin() throws {
        let id = UUID()
        let habitID = UUID()
        let older = ChickMarkGroupCloudSnapshot.GroupRecord(
            id: id, name: "Old", deleted: false,
            revisedAt: old, author: "watch"
        )
        let renamed = ChickMarkGroupCloudSnapshot.GroupRecord(
            id: id, name: "Current", deleted: false,
            revisedAt: recent, author: "iphone"
        )
        let deleted = ChickMarkGroupCloudSnapshot.GroupRecord(
            id: id, name: "Current", deleted: true,
            revisedAt: recent, author: "iphone"
        )
        let assigned = ChickMarkGroupCloudSnapshot.MembershipRecord(
            habitID: habitID, groupID: id, revisedAt: old, author: "watch"
        )
        let unassigned = ChickMarkGroupCloudSnapshot.MembershipRecord(
            habitID: habitID, groupID: nil, revisedAt: recent, author: "iphone"
        )
        let duplicate = ChickMarkGroupCloudSnapshot(
            groups: [older, renamed, deleted, renamed],
            memberships: [assigned, unassigned, assigned]
        )
        // Exercise JSON-decoded legacy/iCloud payloads as well as same-author
        // same-clock conflicting entries, without touching any Cloud account.
        let decoded = try JSONDecoder().decode(
            ChickMarkGroupCloudSnapshot.self,
            from: JSONEncoder().encode(duplicate)
        )
        let canonical = decoded.joined(with: .empty)
        XCTAssertEqual(canonical.groups.count, 1)
        XCTAssertTrue(canonical.groups[0].deleted)
        XCTAssertEqual(canonical.memberships.count, 1)
        XCTAssertNil(canonical.memberships[0].groupID)
        XCTAssertTrue(canonical.materialize().isEmpty)
        XCTAssertEqual(canonical, canonical.joined(with: decoded))
    }

    func testDuplicateRecordsConvergeRegardlessOfOrderOrPeer() {
        let groupID = UUID(), habitID = UUID()
        let created = ChickMarkGroupCloudSnapshot.GroupRecord(
            id: groupID, name: "Work", deleted: false,
            revisedAt: recent, author: "same"
        )
        let removed = ChickMarkGroupCloudSnapshot.GroupRecord(
            id: groupID, name: "Work", deleted: true,
            revisedAt: recent, author: "same"
        )
        let assigned = ChickMarkGroupCloudSnapshot.MembershipRecord(
            habitID: habitID, groupID: groupID,
            revisedAt: recent, author: "same"
        )
        let unassigned = ChickMarkGroupCloudSnapshot.MembershipRecord(
            habitID: habitID, groupID: nil,
            revisedAt: recent, author: "same"
        )
        let left = ChickMarkGroupCloudSnapshot(
            groups: [created, removed, created],
            memberships: [assigned, unassigned]
        )
        let right = ChickMarkGroupCloudSnapshot(
            groups: [removed, created],
            memberships: [unassigned, assigned, unassigned]
        )
        let first = left.joined(with: right)
        let second = right.joined(with: left)
        XCTAssertEqual(first, second)
        XCTAssertTrue(first.materialize().isEmpty)
        XCTAssertEqual(first.groups.count, 1)
        XCTAssertEqual(first.memberships.count, 1)
        XCTAssertEqual(first, first.joined(with: first))
    }

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

    @MainActor
    func testJSONGroupMergePreservesLocalAssignmentsAndAddsMissingMemberships() throws {
        let suite = "ChickMarkGroupMergeQA.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let localGroupID = UUID()
        let importedGroupID = UUID()
        let localHabit = UUID()
        let importedHabit = UUID()
        let newGroupHabit = UUID()
        let local = ChickMarkGroup(
            id: localGroupID, name: "Personal name", habitIDs: [localHabit]
        )
        ChickMarkGroups.save([local], defaults: defaults)
        let incoming = [
            ChickMarkGroup(id: localGroupID, name: "Old backup name",
                           habitIDs: [importedHabit, localHabit, importedHabit]),
            ChickMarkGroup(id: importedGroupID, name: "Other",
                           habitIDs: [localHabit, newGroupHabit])
        ]

        for _ in 0..<2 {
            ChickMarkGroups.merge(incoming, defaults: defaults)
            let result = ChickMarkGroups.load(defaults: defaults)
            XCTAssertEqual(result.count, 2)
            XCTAssertEqual(result[0].name, "Personal name")
            XCTAssertEqual(result[0].habitIDs, [localHabit, importedHabit])
            XCTAssertEqual(result[1].habitIDs, [newGroupHabit])
            XCTAssertEqual(result.flatMap(\.habitIDs).count, 3)
            XCTAssertEqual(Set(result.flatMap(\.habitIDs)).count, 3)
        }
    }

    func testSameAuthorSameClockGroupChangesConvergeRegardlessOfArrivalOrder() {
        let groupID = UUID()
        let base = ChickMarkGroupCloudSnapshot.empty
        let renameA = base.applyingLocalChange(
            from: [],
            to: [ChickMarkGroup(id: groupID, name: "Work", habitIDs: [])],
            at: old, author: "same-device"
        )
        let renameB = base.applyingLocalChange(
            from: [],
            to: [ChickMarkGroup(id: groupID, name: "Workout", habitIDs: [])],
            at: old, author: "same-device"
        )
        XCTAssertEqual(renameA.joined(with: renameB), renameB.joined(with: renameA))
        XCTAssertEqual(
            renameA.joined(with: renameB).joined(with: renameA),
            renameA.joined(with: renameB)
        )
    }

    func testSameClockAndAuthorDeletionCannotResurrectGroup() {
        let id = UUID()
        let group = ChickMarkGroup(id: id, name: "Deleted", habitIDs: [])
        let initial = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [], to: [group], at: old, author: "phone"
        )
        let tombstone = initial.applyingLocalChange(
            from: [group], to: [], at: old, author: "phone"
        )
        let localWins = initial.joined(with: tombstone)
        let remoteWins = tombstone.joined(with: initial)
        XCTAssertEqual(localWins, remoteWins)
        XCTAssertTrue(localWins.materialize().isEmpty)
        XCTAssertTrue(
            remoteWins.joined(with: initial).materialize().isEmpty,
            "Delayed offline copies cannot reanimate a tombstoned group"
        )
    }

    func testSameClockAndAuthorUnassignmentDoesNotRestoreDeletedMembership() {
        let groupID = UUID()
        let habitID = UUID()
        let assigned = ChickMarkGroup(
            id: groupID, name: "Reading", habitIDs: [habitID]
        )
        let original = ChickMarkGroupCloudSnapshot.empty.applyingLocalChange(
            from: [], to: [assigned], at: recent, author: "phone"
        )
        let removed = original.applyingLocalChange(
            from: [assigned],
            to: [ChickMarkGroup(id: groupID, name: "Reading", habitIDs: [])],
            at: recent, author: "phone"
        )
        let a = original.joined(with: removed)
        let b = removed.joined(with: original)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.materialize().first?.habitIDs, [])
        XCTAssertEqual(
            b.joined(with: original).materialize().first?.habitIDs, [],
            "An old in-flight assignment must not revive a removed member"
        )
    }

}
