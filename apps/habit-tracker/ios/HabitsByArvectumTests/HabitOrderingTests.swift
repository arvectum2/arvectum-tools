import XCTest
@testable import HabitsByArvectum

final class HabitOrderingTests: XCTestCase {
    func testExplicitOrderWinsOverCreationDate() {
        let older = Habit(
            name: "Older",
            createdAt: Date(timeIntervalSince1970: 100),
            sortOrder: 5
        )
        let newer = Habit(
            name: "Newer",
            createdAt: Date(timeIntervalSince1970: 200),
            sortOrder: 1
        )

        XCTAssertEqual(
            HabitOrdering.sorted([older, newer]).map(\.name),
            ["Newer", "Older"]
        )
    }

    func testLegacyEqualOrdersFallBackToCreationDate() {
        let older = Habit(
            name: "Older",
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let newer = Habit(
            name: "Newer",
            createdAt: Date(timeIntervalSince1970: 200)
        )

        XCTAssertEqual(
            HabitOrdering.sorted([newer, older]).map(\.name),
            ["Older", "Newer"]
        )
    }

    func testNextOrderAppendsAfterLargestValue() {
        let habits = [
            Habit(name: "One", sortOrder: 2),
            Habit(name: "Two", sortOrder: 8),
            Habit(name: "Three", sortOrder: 4)
        ]

        XCTAssertEqual(HabitOrdering.nextOrder(in: habits), 9)
        XCTAssertEqual(HabitOrdering.nextOrder(in: []), 0)
    }
}
