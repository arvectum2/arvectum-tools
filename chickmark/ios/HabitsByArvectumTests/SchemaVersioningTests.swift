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

    @MainActor
    func testPublishedV1FullHistorySurvivesV2SeparateStoreRestartAndJSONMerge() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("A1-Upgrade-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let habitsURL = directory.appendingPathComponent("Habits.store")
        let remindersURL = directory.appendingPathComponent("OneOffReminders.store")
        let v1Schema = Schema(versionedSchema: HabitsSchemaV1.self)
        let fullSchema = HabitsSchema.current
        let localSchema = Schema([OneOffReminder.self])
        let habitID = UUID()
        let oldCheckID = UUID()
        let oldSkipID = UUID()
        let oldPauseID = UUID()
        let oldMutationID = UUID()
        let dueDate = Date(timeIntervalSince1970: 1_756_598_400)
        let skipDate = dueDate.addingTimeInterval(86_400)
        let pauseDate = dueDate.addingTimeInterval(2 * 86_400)
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let firstDayKey = HabitDayKey.make(for: dueDate, calendar: london)
        let skipDayKey = HabitDayKey.make(for: skipDate, calendar: london)
        let pauseDayKey = HabitDayKey.make(for: pauseDate, calendar: london)

        func habitsConfiguration() -> ModelConfiguration {
            ModelConfiguration(
                "Habits", schema: v1Schema, url: habitsURL,
                allowsSave: true, cloudKitDatabase: .none
            )
        }
        func remindersConfiguration() -> ModelConfiguration {
            ModelConfiguration(
                "OneOffReminders", schema: localSchema, url: remindersURL,
                allowsSave: true, cloudKitDatabase: .none
            )
        }

        // Seed the *published* v1 disk store; no new-model reminders existed
        // in this location when the user originally created these records.
        do {
            let container = try ModelContainer(
                for: v1Schema, configurations: [habitsConfiguration()]
            )
            let context = ModelContext(container)
            context.insert(Habit(
                id: habitID, name: "Saved reading history",
                symbolName: "book.fill", createdAt: dueDate,
                isArchived: false, reminderEnabled: true,
                reminderHour: 7, reminderMinute: 15, weeklyTarget: 3,
                sortOrder: 9
            ))
            context.insert(HabitCheckIn(
                id: oldCheckID, habitID: habitID, day: dueDate,
                createdAt: dueDate, calendar: london
            ))
            context.insert(HabitSkip(
                id: oldSkipID, habitID: habitID, day: skipDate,
                createdAt: skipDate, calendar: london
            ))
            context.insert(HabitPausePeriod(
                id: oldPauseID, habitID: habitID, startedAt: pauseDate,
                endedAt: pauseDate.addingTimeInterval(86_400), calendar: london
            ))
            context.insert(HabitDayMutation(
                id: oldMutationID, habitID: habitID, dayKey: firstDayKey,
                updatedAt: dueDate, mutationID: UUID()
            ))
            try context.save()
        }

        var export: ChickMarkBackup?
        let reminderID = UUID()
        // Upgrade by splitting published V1 habits from local-only
        // reminders, exactly like the App boot configuration.
        do {
            let upgraded = try ModelContainer(
                for: fullSchema, migrationPlan: HabitsMigrationPlan.self,
                configurations: [habitsConfiguration(), remindersConfiguration()]
            )
            let context = ModelContext(upgraded)
            let habits = try context.fetch(FetchDescriptor<Habit>())
            XCTAssertEqual(habits.map(\.id), [habitID])
            XCTAssertEqual(habits.first?.name, "Saved reading history")
            XCTAssertEqual(habits.first?.weeklyTarget, 3)
            XCTAssertEqual(habits.first?.sortOrder, 9)
            XCTAssertEqual(habits.first?.reminderHour, 7)
            XCTAssertEqual(habits.first?.reminderMinute, 15)
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitCheckIn>())
                .map(\.dayKey), [firstDayKey])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitSkip>())
                .map(\.dayKey), [skipDayKey])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitPausePeriod>())
                .map(\.startDayKey), [pauseDayKey])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitDayMutation>())
                .map(\.dayKey), [firstDayKey])
            context.insert(OneOffReminder(
                id: reminderID, title: "New after upgrade", dueAt: dueDate
            ))
            try context.save()
            export = try ChickMarkBackupService.capture(from: context)
        }

        // Exercise disk persistence across a complete container lifecycle.
        do {
            let restarted = try ModelContainer(
                for: fullSchema, migrationPlan: HabitsMigrationPlan.self,
                configurations: [habitsConfiguration(), remindersConfiguration()]
            )
            let context = ModelContext(restarted)
            XCTAssertEqual(try context.fetch(FetchDescriptor<Habit>())
                .map(\.id), [habitID])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitCheckIn>())
                .map(\.id), [oldCheckID])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitSkip>())
                .map(\.id), [oldSkipID])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitPausePeriod>())
                .map(\.id), [oldPauseID])
            XCTAssertEqual(try context.fetch(FetchDescriptor<HabitDayMutation>())
                .map(\.id), [oldMutationID])
            XCTAssertEqual(try context.fetch(FetchDescriptor<OneOffReminder>())
                .map(\.id), [reminderID])
        }

        let document = try XCTUnwrap(export)
        let JSON = try JSONEncoder().encode(document)
        let imported = try JSONDecoder().decode(ChickMarkBackup.self, from: JSON)
        try imported.validate()
        let isolatedConfig = ModelConfiguration(
            "A1-IsolatedBackupDestination", schema: fullSchema,
            isStoredInMemoryOnly: true, cloudKitDatabase: .none
        )
        let isolated = try ModelContainer(for: fullSchema, configurations: [isolatedConfig])
        let target = ModelContext(isolated)
        let deviceHabit = Habit(name: "Existing second device data")
        target.insert(deviceHabit)
        let deviceCheck = HabitCheckIn(habitID: deviceHabit.id, day: .now)
        target.insert(deviceCheck)
        try target.save()
        for _ in 0..<2 {
            try ChickMarkBackupService.restore(imported, to: target, mode: .merge)
            XCTAssertEqual(try target.fetch(FetchDescriptor<Habit>()).count, 2)
            XCTAssertEqual(try target.fetch(FetchDescriptor<HabitCheckIn>()).count, 2)
            XCTAssertEqual(try target.fetch(FetchDescriptor<HabitSkip>()).count, 1)
            XCTAssertEqual(try target.fetch(FetchDescriptor<HabitPausePeriod>()).count, 1)
            XCTAssertEqual(try target.fetch(FetchDescriptor<HabitDayMutation>()).count, 1)
            XCTAssertEqual(try target.fetch(FetchDescriptor<OneOffReminder>()).count, 1)
            XCTAssertTrue(try target.fetch(FetchDescriptor<HabitCheckIn>())
                .contains { $0.id == deviceCheck.id })
            XCTAssertTrue(try target.fetch(FetchDescriptor<HabitCheckIn>())
                .contains { $0.id == oldCheckID && $0.dayKey == firstDayKey })
        }
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
