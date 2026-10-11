import SwiftData
import XCTest
@testable import HabitsByArvectum

final class SchemaVersioningTests: XCTestCase {
    func testCurrentSchemaIsExplicitlyVersioned() {
        XCTAssertEqual(
            HabitsSchemaV1.versionIdentifier,
            Schema.Version(1, 0, 0)
        )
        XCTAssertEqual(
            HabitsSchemaV2.versionIdentifier,
            Schema.Version(2, 0, 0)
        )
        XCTAssertEqual(HabitsMigrationPlan.schemas.count, 2)
        XCTAssertEqual(HabitsMigrationPlan.stages.count, 1)
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
        XCTAssertTrue(entityNames.contains("OneOffReminder"))
        XCTAssertEqual(entityNames.count, 6)
    }

    func testPublishedV1HabitStoreOpensBesideNewLocalReminderStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let habitsURL = directory.appendingPathComponent("Habits.store")
        let oneOffURL = directory.appendingPathComponent(
            "OneOffReminders.store"
        )
        let v1Schema = Schema(versionedSchema: HabitsSchemaV1.self)

        do {
            let v1Config = ModelConfiguration(
                "Habits",
                schema: v1Schema,
                url: habitsURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )
            let v1Container = try ModelContainer(
                for: v1Schema,
                configurations: [v1Config]
            )
            let context = ModelContext(v1Container)
            context.insert(Habit(name: "Published V1 habit"))
            try context.save()
        }

        let fullSchema = Schema(versionedSchema: HabitsSchemaV2.self)
        let habitsConfig = ModelConfiguration(
            "Habits",
            schema: v1Schema,
            url: habitsURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let oneOffSchema = Schema([OneOffReminder.self])
        let oneOffConfig = ModelConfiguration(
            "OneOffReminders",
            schema: oneOffSchema,
            url: oneOffURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let upgraded = try ModelContainer(
            for: fullSchema,
            migrationPlan: HabitsMigrationPlan.self,
            configurations: [habitsConfig, oneOffConfig]
        )
        let context = ModelContext(upgraded)

        XCTAssertEqual(
            try context.fetch(FetchDescriptor<Habit>()).map(\.name),
            ["Published V1 habit"]
        )

        context.insert(
            OneOffReminder(
                title: "Buy marathon slot",
                dueAt: .now.addingTimeInterval(3600)
            )
        )
        try context.save()

        XCTAssertEqual(
            try context.fetch(FetchDescriptor<OneOffReminder>()).count,
            1
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: oneOffURL.path))
    }
}
