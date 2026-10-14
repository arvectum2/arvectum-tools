import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class HabitMultiCheckTests: XCTestCase {
    private let dayKey = "2026-10-10"

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }

    private func container() throws -> ModelContainer {
        let schema = Schema([Habit.self, HabitCheckIn.self, HabitSkip.self,
                             HabitPausePeriod.self, HabitDayMutation.self])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
        )
    }

    func testDailyTargetPreservesPublishedRecurrenceSemantics() {
        let habit = Habit(name: "Water")
        XCTAssertEqual(habit.dailyTarget, 1)
        XCTAssertFalse(habit.usesDailyMultiple)
        habit.dailyTarget = 5
        XCTAssertTrue(habit.usesDailyMultiple)
        XCTAssertFalse(habit.usesFlexibleWeeklyTarget)
        XCTAssertFalse(habit.usesCompletionInterval)
        XCTAssertEqual(habit.dailyTarget, 5)
        XCTAssertEqual(habit.schedule, .everyDay)
        let sameStoredHabit = Habit(name: "Water", weeklyTarget: habit.weeklyTarget)
        XCTAssertEqual(sameStoredHabit.dailyTarget, 5)
        let weekly = Habit(name: "Run", weeklyTarget: 3)
        XCTAssertTrue(weekly.usesFlexibleWeeklyTarget)
        XCTAssertEqual(weekly.dailyTarget, 1)
    }

    func testIndependentSlotsPartialNotCompletedUntilAllFive() throws {
        let context = ModelContext(try container())
        let habit = Habit(name: "Water")
        habit.dailyTarget = 5
        context.insert(habit)

        for slot in [3, 1, 5, 2] {
            XCTAssertTrue(HabitMultiCheckMutation.setSlot(
                habitID: habit.id, dayKey: dayKey, slot: slot,
                enabled: true, context: context, calendar: calendar
            ))
        }
        try context.save()
        let rows = try context.fetch(FetchDescriptor<HabitCheckIn>())
        let positions = HabitMultiCheck.slots(
            habitID: habit.id, dayKey: dayKey, target: 5, checkIns: rows
        )
        XCTAssertEqual(Set(positions.keys), [1, 2, 3, 5])
        let date = try XCTUnwrap(HabitMultiCheck.date(from: dayKey, calendar: calendar))
        XCTAssertFalse(HabitMetrics.isCompleted(
            habitID: habit.id, on: date,
            checkIns: rows, calendar: calendar, target: 5
        ))
        XCTAssertTrue(HabitMultiCheckMutation.setSlot(
            habitID: habit.id, dayKey: dayKey, slot: 4,
            enabled: true, context: context, calendar: calendar
        ))
        try context.save()
        XCTAssertTrue(HabitMetrics.isCompleted(
            habitID: habit.id, on: date,
            checkIns: try context.fetch(FetchDescriptor<HabitCheckIn>()),
            calendar: calendar, target: 5
        ))
        XCTAssertTrue(HabitMultiCheckMutation.setSlot(
            habitID: habit.id, dayKey: dayKey, slot: 3,
            enabled: false, context: context, calendar: calendar
        ))
        try context.save()
        XCTAssertFalse(HabitMetrics.isCompleted(
            habitID: habit.id, on: date,
            checkIns: try context.fetch(FetchDescriptor<HabitCheckIn>()),
            calendar: calendar, target: 5
        ))
    }

    func testBinaryWatchCommandFillsAndClearsTarget() throws {
        let context = ModelContext(try container())
        let habit = Habit(name: "Hydrate")
        habit.dailyTarget = 3
        context.insert(habit)
        XCTAssertTrue(HabitCompletionMutation.setCompletion(
            habitID: habit.id, dayKey: dayKey,
            completed: true, context: context, calendar: calendar
        ))
        try context.save()
        XCTAssertEqual(try context.fetch(FetchDescriptor<HabitCheckIn>()).count, 3)
        XCTAssertTrue(HabitCompletionMutation.setCompletion(
            habitID: habit.id, dayKey: dayKey,
            completed: false, context: context, calendar: calendar
        ))
        try context.save()
        XCTAssertTrue(try context.fetch(FetchDescriptor<HabitCheckIn>()).isEmpty)
    }

    func testQuantityGoalReachesTargetAfterFourActions() throws {
        let context = ModelContext(try container())
        let habit = Habit(name: "Drink water", weeklyTarget: 3004)
        context.insert(habit)
        XCTAssertTrue(habit.usesQuantitativeGoal)
        XCTAssertEqual(habit.dailyTarget, 4)
        for slot in 1...3 {
            XCTAssertTrue(HabitMultiCheckMutation.setSlot(
                habitID: habit.id, dayKey: dayKey, slot: slot,
                enabled: true, context: context, calendar: calendar
            ))
        }
        try context.save()
        let date = try XCTUnwrap(HabitMultiCheck.date(from: dayKey, calendar: calendar))
        XCTAssertFalse(HabitMetrics.isCompleted(
            habitID: habit.id, on: date,
            checkIns: try context.fetch(FetchDescriptor<HabitCheckIn>()),
            calendar: calendar, target: habit.dailyTarget
        ))
        XCTAssertTrue(HabitMultiCheckMutation.setSlot(
            habitID: habit.id, dayKey: dayKey, slot: 4,
            enabled: true, context: context, calendar: calendar
        ))
        try context.save()
        XCTAssertTrue(HabitMetrics.isCompleted(
            habitID: habit.id, on: date,
            checkIns: try context.fetch(FetchDescriptor<HabitCheckIn>()),
            calendar: calendar, target: habit.dailyTarget
        ))
    }

    func testDurationGoalTracksFixedFiveMinuteSegments() {
        let habit = Habit(name: "Read", weeklyTarget: 5004)
        XCTAssertTrue(habit.usesDurationGoal)
        XCTAssertFalse(habit.usesFlexibleWeeklyTarget)
        XCTAssertEqual(habit.dailyTarget, 4)
        XCTAssertEqual(habit.durationMinutes, 20)
    }

    func testIdenticalSlotIdsAreStableForOfflineDuplicateDelivery() {
        let id = UUID()
        XCTAssertEqual(HabitMultiCheck.slotID(habitID: id, dayKey: dayKey, slot: 1),
                       HabitMultiCheck.slotID(habitID: id, dayKey: dayKey, slot: 1))
        XCTAssertNotEqual(HabitMultiCheck.slotID(habitID: id, dayKey: dayKey, slot: 1),
                          HabitMultiCheck.slotID(habitID: id, dayKey: dayKey, slot: 2))
    }
}

extension HabitMultiCheckTests {
    func testPartialFiveCheckGoalStaysPartialAcrossDSTAndTimezoneTravel() throws {
        let context = ModelContext(try container())
        let habit = Habit(name: "Water", createdAt: .distantPast)
        habit.dailyTarget = 5
        context.insert(habit)

        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        var london = Calendar(identifier: .gregorian)
        london.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        let dayKey = "2026-11-01" // 25-hour US DST autumn day
        let day = try XCTUnwrap(HabitMultiCheck.date(from: dayKey, calendar: ny))

        for slot in 1...4 {
            XCTAssertTrue(HabitMultiCheckMutation.setSlot(
                habitID: habit.id, dayKey: dayKey, slot: slot,
                enabled: true, context: context, calendar: ny
            ))
        }
        try context.save()
        var entries = try context.fetch(FetchDescriptor<HabitCheckIn>())
        XCTAssertFalse(HabitMetrics.isCompleted(
            habitID: habit.id, on: day, checkIns: entries, calendar: ny, target: 5
        ))
        // Day is keyed by the originally selected local date; a timezone
        // change must neither complete the partially filled day nor add slots.
        let sameKeyLondon = try XCTUnwrap(HabitMultiCheck.date(
            from: dayKey, calendar: london
        ))
        XCTAssertFalse(HabitMetrics.isCompleted(
            habitID: habit.id, on: sameKeyLondon,
            checkIns: entries, calendar: london, target: 5
        ))
        XCTAssertTrue(HabitMultiCheckMutation.setSlot(
            habitID: habit.id, dayKey: dayKey, slot: 5,
            enabled: true, context: context, calendar: ny
        ))
        try context.save()
        entries = try context.fetch(FetchDescriptor<HabitCheckIn>())
        XCTAssertTrue(HabitMetrics.isCompleted(
            habitID: habit.id, on: sameKeyLondon,
            checkIns: entries, calendar: london, target: 5
        ))
        let nextDay = try XCTUnwrap(ny.date(byAdding: .day, value: 1, to: day))
        XCTAssertFalse(HabitMetrics.isCompleted(
            habitID: habit.id, on: nextDay,
            checkIns: entries, calendar: ny, target: 5
        ))
    }
}
