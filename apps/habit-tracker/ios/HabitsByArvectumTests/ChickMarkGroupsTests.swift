import XCTest
@testable import HabitsByArvectum

final class ChickMarkGroupsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "ChickMarkGroupsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testCreateAssignMoveAndRemoveWithoutRemovingHabit() throws {
        let first = try XCTUnwrap(
            ChickMarkGroups.create(name: "Health", defaults: defaults)
        )
        let second = try XCTUnwrap(
            ChickMarkGroups.create(name: "Work", defaults: defaults)
        )
        let habitID = UUID()
        ChickMarkGroups.assign(habitID: habitID, to: first.id, defaults: defaults)
        XCTAssertEqual(
            ChickMarkGroups.groupID(for: habitID, defaults: defaults),
            first.id
        )
        ChickMarkGroups.assign(habitID: habitID, to: second.id, defaults: defaults)
        XCTAssertEqual(
            ChickMarkGroups.groupID(for: habitID, defaults: defaults),
            second.id
        )
        XCTAssertFalse(ChickMarkGroups.load(defaults: defaults)[0].habitIDs.contains(habitID))
        ChickMarkGroups.delete(id: second.id, defaults: defaults)
        XCTAssertNil(ChickMarkGroups.groupID(for: habitID, defaults: defaults))
        XCTAssertEqual(ChickMarkGroups.load(defaults: defaults).count, 1)
    }

    func testDuplicateNameNotCreatedAndMergeIdempotent() throws {
        let first = try XCTUnwrap(
            ChickMarkGroups.create(name: "  Home  ", defaults: defaults)
        )
        XCTAssertNil(ChickMarkGroups.create(name: "home", defaults: defaults))
        let other = ChickMarkGroup(id: UUID(), name: "Study", habitIDs: [])
        ChickMarkGroups.merge([first, other], defaults: defaults)
        ChickMarkGroups.merge([first, other], defaults: defaults)
        XCTAssertEqual(ChickMarkGroups.load(defaults: defaults).count, 2)
    }
}
