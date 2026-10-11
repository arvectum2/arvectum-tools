import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class HabitNotificationActionTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    func testNotificationActionCompletesDueHabit() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habit = Habit(name: "Read")
        context.insert(habit)
        try context.save()

        HabitNotificationActionCoordinator.shared.configure(
            modelContainer: container
        )
        let date = Date(timeIntervalSince1970: 1_759_276_800)

        XCTAssertTrue(
            HabitNotificationActionCoordinator.shared.markCompleted(
                habitID: habit.id,
                at: date,
                mutationID: UUID(),
                calendar: calendar
            )
        )

        let checkIns = try context.fetch(FetchDescriptor<HabitCheckIn>())
        XCTAssertEqual(checkIns.count, 1)
        XCTAssertEqual(checkIns.first?.habitID, habit.id)
    }

    func testNotificationSkipCreatesSkipAndRemovesCompletion() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habit = Habit(name: "Read")
        context.insert(habit)
        try context.save()

        HabitNotificationActionCoordinator.shared.configure(
            modelContainer: container
        )
        let date = Date(timeIntervalSince1970: 1_759_276_800)

        XCTAssertTrue(
            HabitNotificationActionCoordinator.shared.markCompleted(
                habitID: habit.id,
                at: date,
                mutationID: UUID(
                    uuidString: "00000000-0000-0000-0000-000000000001"
                )!,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            HabitNotificationActionCoordinator.shared.skipToday(
                habitID: habit.id,
                at: date.addingTimeInterval(1),
                mutationID: UUID(
                    uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"
                )!,
                calendar: calendar
            )
        )

        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
        let skips = try context.fetch(FetchDescriptor<HabitSkip>())
        XCTAssertEqual(skips.count, 1)
        XCTAssertEqual(skips.first?.habitID, habit.id)
    }

    func testNotificationActionCompletesOneOffReminder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let reminder = OneOffReminder(
            title: "Buy marathon slot",
            dueAt: .now.addingTimeInterval(3600)
        )
        context.insert(reminder)
        try context.save()

        HabitNotificationActionCoordinator.shared.configure(
            modelContainer: container
        )

        XCTAssertTrue(
            HabitNotificationActionCoordinator.shared
                .markOneOffCompleted(reminderID: reminder.id)
        )

        let reminders = try context.fetch(
            FetchDescriptor<OneOffReminder>()
        )
        XCTAssertEqual(reminders.count, 1)
        XCTAssertTrue(reminders[0].isCompleted)
        XCTAssertNotNil(reminders[0].completedAt)
    }

    func testNotificationActionIgnoresArchivedHabit() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let habit = Habit(name: "Read", isArchived: true)
        context.insert(habit)
        try context.save()

        HabitNotificationActionCoordinator.shared.configure(
            modelContainer: container
        )

        XCTAssertFalse(
            HabitNotificationActionCoordinator.shared.markCompleted(
                habitID: habit.id,
                calendar: calendar
            )
        )
        XCTAssertTrue(
            try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty
        )
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Habit.self,
            HabitCheckIn.self,
            HabitSkip.self,
            HabitPausePeriod.self,
            HabitDayMutation.self,
            OneOffReminder.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
