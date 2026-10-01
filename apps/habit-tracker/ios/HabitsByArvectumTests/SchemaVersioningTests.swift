import SwiftData
import XCTest
@testable import HabitsByArvectum

final class SchemaVersioningTests: XCTestCase {
    func testCurrentSchemaIsExplicitlyVersioned() {
        XCTAssertEqual(
            HabitsSchemaV1.versionIdentifier,
            Schema.Version(1, 0, 0)
        )
        XCTAssertEqual(HabitsMigrationPlan.schemas.count, 1)
        XCTAssertTrue(HabitsMigrationPlan.stages.isEmpty)
    }

    func testCurrentSchemaContainsAllPersistentModels() {
        let entityNames = Set(
            HabitsSchema.current.entities.map(\.name)
        )

        XCTAssertTrue(entityNames.contains("Habit"))
        XCTAssertTrue(entityNames.contains("HabitCheckIn"))
        XCTAssertTrue(entityNames.contains("HabitSkip"))
        XCTAssertTrue(entityNames.contains("HabitPausePeriod"))
        XCTAssertTrue(entityNames.contains("HabitDayMutation"))
        XCTAssertEqual(entityNames.count, 5)
    }
}
