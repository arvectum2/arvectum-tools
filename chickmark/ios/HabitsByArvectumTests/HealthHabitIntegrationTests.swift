import SwiftData
import XCTest
@testable import HabitsByArvectum

@MainActor
final class HealthHabitIntegrationTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testRulePreferencesAreOptInAndLocal() {
        let suite = "HealthHabitIntegrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = HealthHabitRuleStore(defaults: defaults)
        let habit = UUID()
        XCTAssertNil(store.rule(for: habit))
        let rule = HealthHabitRule(metric: .walkingDistance, target: 2.5, enabledAt: .now)
        store.save(rule, for: habit)
        XCTAssertEqual(HealthHabitRuleStore(defaults: defaults).rule(for: habit), rule)
        store.disable(for: habit)
        XCTAssertNil(store.rule(for: habit))
    }

    func testAutomaticCompletionHonorsUserActions() {
        let day = date(2026, 10, 12)
        let habit = Habit(name: "Walk", createdAt: day)
        let rule = HealthHabitRule(metric: .steps, target: 5_000, enabledAt: day)
        let key = HabitDayKey.make(for: day, calendar: calendar)
        let eligible: ([HabitCheckIn], [HabitSkip], [HabitDayMutation]) -> Bool = {
            HealthHabitAutoPolicy.shouldComplete(
                habit: habit, rule: rule, day: day, now: day.addingTimeInterval(3600),
                checkIns: $0, skips: $1, pausePeriods: [], mutations: $2, calendar: self.calendar
            )
        }
        XCTAssertTrue(eligible([], [], []))
        XCTAssertFalse(eligible([HabitCheckIn(habitID: habit.id, day: day, calendar: calendar)], [], []))
        XCTAssertFalse(eligible([], [HabitSkip(habitID: habit.id, day: day, calendar: calendar)], []))
        XCTAssertFalse(eligible([], [], [
            HabitDayMutation(habitID: habit.id, dayKey: key, updatedAt: day, mutationID: UUID())
        ]))
        habit.pausedAt = day
        XCTAssertFalse(eligible([], [], []))
        habit.pausedAt = nil
        habit.schedule = .tuesday
        XCTAssertFalse(eligible([], [], []))
        habit.schedule = .everyDay
        habit.isArchived = true
        XCTAssertFalse(eligible([], [], []))
        habit.isArchived = false
        let futureRule = HealthHabitRule(metric: .steps, target: 5_000,
                                         enabledAt: day.addingTimeInterval(24 * 60 * 60))
        XCTAssertFalse(HealthHabitAutoPolicy.shouldComplete(
            habit: habit, rule: futureRule, day: day, now: day.addingTimeInterval(3600),
            checkIns: [], skips: [], pausePeriods: [], mutations: [], calendar: calendar
        ))
    }

    func testTodaysHealthTargetRecompletesAfterManualUncheck() {
        let day = date(2026, 10, 12)
        let now = day.addingTimeInterval(3600)
        let habit = Habit(name: "Walk", createdAt: day)
        let rule = HealthHabitRule(metric: .steps, target: 7777, enabledAt: day)
        let mutation = HabitDayMutation(
            habitID: habit.id, dayKey: HabitDayKey.make(for: day, calendar: calendar),
            updatedAt: now, mutationID: UUID()
        )
        let eligible: (Bool, [HabitSkip], [HabitCheckIn]) -> Bool = {
            HealthHabitAutoPolicy.shouldComplete(
                habit: habit, rule: rule, day: day, now: now,
                checkIns: $2, skips: $1, pausePeriods: [], mutations: [mutation],
                allowTodayRecompletionAfterUndo: $0, calendar: self.calendar
            )
        }

        // Existing manual undo blocks before the threshold is met.
        XCTAssertFalse(eligible(false, [], []))
        // A verified current reading of 9316 / 7777 lifts the old block.
        XCTAssertTrue(eligible(true, [], []))
        // Explicit skips and manual check-ins still take precedence.
        XCTAssertFalse(eligible(true, [HabitSkip(habitID: habit.id, day: day)], []))
        XCTAssertFalse(eligible(true, [], [HabitCheckIn(
            habitID: habit.id, day: day, calendar: calendar
        )]))
        // Never revive historical manually undone days.
        XCTAssertFalse(HealthHabitAutoPolicy.shouldComplete(
            habit: habit, rule: rule, day: day,
            now: day.addingTimeInterval(24 * 3600),
            checkIns: [], skips: [], pausePeriods: [], mutations: [mutation],
            allowTodayRecompletionAfterUndo: true, calendar: calendar
        ))
    }

    func testProgressFormatsActualStepsWithLocaleAndClampsBarOnly() {
        let progress = HealthHabitProgress(
            metric: .steps, current: 3333, target: 7777, dayKey: "2026-10-12"
        )
        let ru = progress.quantityText(locale: Locale(identifier: "ru_RU"))
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
        XCTAssertEqual(ru, "3 333 / 7 777")
        XCTAssertEqual(progress.fraction, 3333.0 / 7777.0, accuracy: 0.0001)

        let exceeded = HealthHabitProgress(
            metric: .steps, current: 8000, target: 7777, dayKey: "2026-10-12"
        )
        XCTAssertEqual(exceeded.fraction, 1)
        XCTAssertTrue(exceeded.quantityText(locale: Locale(identifier: "en_US"))
            .contains("8,000 / 7,777"))
        XCTAssertEqual(HealthHabitProgress(
            metric: .steps, current: 0, target: 7777, dayKey: "2026-10-12"
        ).fraction, 0)

        let distance = HealthHabitProgress(
            metric: .walkingDistance, current: 2.4, target: 3.5, dayKey: "2026-10-12"
        )
        XCTAssertEqual(distance.quantityText(locale: Locale(identifier: "en_US")),
                       "2.4 / 3.5")
    }

    func testMetricConvertsDistanceAndValidatesThreshold() {
        XCTAssertEqual(HealthHabitMetric.walkingDistance.normalized(2_500), 2.5)
        XCTAssertEqual(HealthHabitMetric.steps.normalized(5_000), 5_000)
        XCTAssertFalse(HealthHabitRule(metric: .steps, target: 0, enabledAt: .now).isValid)
    }

    func testManualOverrideReplacesAutoAttribution() {
        let suite = "HealthHabitEvidenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HealthHabitRuleStore(defaults: defaults)
        let habit = UUID(), mutation = UUID()
        store.record(HealthHabitEvidence(mutationID: mutation, metric: .steps, markedAt: .now),
                     habitID: habit, dayKey: "2026-10-12")
        XCTAssertEqual(store.source(for: habit, dayKey: "2026-10-12", mutationID: mutation), .steps)
        XCTAssertNil(store.source(for: habit, dayKey: "2026-10-12", mutationID: UUID()))
    }

    func testSleepUsesActualOverlappingIntervalsOnlyOnce() {
        let start = date(2026, 10, 12)
        let end = start.addingTimeInterval(10 * 3600)
        let intervals = [
            HealthSleepInterval(start: start, end: start.addingTimeInterval(4 * 3600)),
            HealthSleepInterval(start: start.addingTimeInterval(3 * 3600),
                                end: start.addingTimeInterval(7 * 3600)),
            // Another tracker can report the same sleep interval.
            HealthSleepInterval(start: start.addingTimeInterval(1 * 3600),
                                end: start.addingTimeInterval(6 * 3600)),
            HealthSleepInterval(start: start.addingTimeInterval(-3600),
                                end: start.addingTimeInterval(3600)),
            HealthSleepInterval(start: end.addingTimeInterval(3600),
                                end: end.addingTimeInterval(7200))
        ]
        XCTAssertEqual(HealthSleepIntervals.totalDuration(intervals, from: start, to: end),
                       7 * 3600)
        XCTAssertEqual(HealthSleepIntervals.totalDuration([], from: start, to: end), 0)
    }

    func testRunningWeeklyGoalOnlyCountsEligibleDays() {
        let day = date(2026, 10, 15)
        let habit = Habit(name: "Run", createdAt: day.addingTimeInterval(-86400))
        habit.goalMode = .weekly(times: 3)
        let rule = HealthHabitRule(metric: .runningWorkout, target: 20,
                                   enabledAt: day.addingTimeInterval(-86400))
        let ordinaryRule = HealthHabitRule(metric: .steps, target: 5000,
                                           enabledAt: day.addingTimeInterval(-86400))
        let isEligible: (HealthHabitRule, [HabitCheckIn]) -> Bool = { rule, checkIns in
            HealthHabitAutoPolicy.shouldComplete(
                habit: habit, rule: rule, day: day, now: day.addingTimeInterval(3600),
                checkIns: checkIns, skips: [], pausePeriods: [], mutations: [], calendar: self.calendar
            )
        }
        XCTAssertTrue(isEligible(rule, []))
        XCTAssertFalse(isEligible(ordinaryRule, []))
        let weekStart = HabitFrequency.startOfWeek(containing: day, calendar: calendar)
        let alreadyDone = (0..<3).map { offset in
            HabitCheckIn(habitID: habit.id,
                         day: calendar.date(byAdding: .day, value: offset, to: weekStart)!,
                         calendar: calendar)
        }
        XCTAssertFalse(isEligible(rule, alreadyDone))
    }

    func testSmartMetricDefaultsAndTypes() {
        XCTAssertEqual(HealthHabitMetric.sleepHours.defaultTarget, 7)
        XCTAssertEqual(HealthHabitMetric.runningWorkout.defaultTarget, 20)
        XCTAssertTrue(HealthHabitMetric.runningWorkout.supportsWeeklyGoal)
        XCTAssertFalse(HealthHabitMetric.sleepHours.supportsWeeklyGoal)
        XCTAssertNotEqual(HealthHabitMetric.sleepHours.sampleType,
                          HealthHabitMetric.runningWorkout.sampleType)
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
