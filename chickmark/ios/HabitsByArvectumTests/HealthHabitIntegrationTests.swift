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

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
}
