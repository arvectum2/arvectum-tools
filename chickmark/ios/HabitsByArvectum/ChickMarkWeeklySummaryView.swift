import SwiftData
import SwiftUI

/// Visible only when the user explicitly opts in. No reminders or analytics.
/// Health-linked habits are omitted: manual records cannot prove historic
/// HealthKit completions without querying health history and consent.
struct ChickMarkWeeklySummaryView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]
    @Query(sort: \HabitSkip.day) private var skips: [HabitSkip]
    @Query(sort: \HabitPausePeriod.startedAt) private var pauses: [HabitPausePeriod]

    @AppStorage("chickmark.weeklySummary.enabled")
    private var enabled = false

    private var includedHabits: [Habit] {
        habits.filter {
            !$0.isArchived &&
            HealthHabitRuleStore.shared.rule(for: $0.id) == nil
        }
    }

    private var weekly: ChickMarkWeeklyReport {
        ChickMarkWeeklySummary.report(
            habits: includedHabits, checkIns: checkIns,
            skips: skips, pausePeriods: pauses
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(L10n.string("weekly.optIn"), isOn: $enabled)
                    .accessibilityIdentifier("weekly-opt-in")
            } footer: {
                Text(L10n.string("weekly.privacy"))
            }

            if enabled {
                Section(L10n.string("weekly.lastCompleted")) {
                    HStack {
                        Text(L10n.string("weekly.calendarWeek"))
                        Spacer()
                        Text(weekRange(weekly.lastWeek.weekStart))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    LabeledContent(
                        L10n.string("weekly.scheduled"),
                        value: L10n.format(
                            "weekly.ratio",
                            weekly.lastWeek.scheduledCompleted,
                            weekly.lastWeek.scheduledEligible
                        )
                    )
                    LabeledContent(
                        L10n.string("weekly.neutral"),
                        value: "\(weekly.lastWeek.scheduledNeutral)"
                    )
                    LabeledContent(
                        L10n.string("weekly.flexible"),
                        value: L10n.format(
                            "weekly.ratio",
                            weekly.lastWeek.flexibleGoalsMet,
                            weekly.lastWeek.flexibleGoalsEligible
                        )
                    )
                    LabeledContent(
                        L10n.string("weekly.rolling"),
                        value: "\(weekly.lastWeek.intervalOccurrences)"
                    )
                }

                Section {
                    LabeledContent(
                        L10n.string("weekly.completedDays"),
                        value: "\(weekly.lastWeek.completionDays)"
                    )
                    if let best = weekly.lastWeek.bestDay {
                        LabeledContent(
                            L10n.string("weekly.bestDay"),
                            value: L10n.format(
                                "weekly.bestDay.format",
                                label(best), weekly.lastWeek.bestDayCompletions
                            )
                        )
                    } else {
                        LabeledContent(
                            L10n.string("weekly.bestDay"),
                            value: L10n.string("insights.noData")
                        )
                    }
                    LabeledContent(
                        L10n.string("weekly.trend"),
                        value: changeText(weekly.changeInCompletions)
                    )
                } header: {
                    Text(L10n.string("weekly.activity"))
                } footer: {
                    Text(L10n.string("weekly.note"))
                }
            }
        }
        .navigationTitle(L10n.string("weekly.title"))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("weekly-summary")
    }

    private func label(_ date: Date) -> String {
        let chosen = ChickMarkLanguage.selected
        let locale = ChickMarkLanguage.supported.contains(chosen)
            ? Locale(identifier: chosen)
            : .current
        return date.formatted(
            .dateTime.weekday(.wide).locale(locale)
        )
    }

    private func weekRange(_ start: Date) -> String {
        let calendar = Calendar.autoupdatingCurrent
        let last = calendar.date(
            byAdding: .day, value: 6, to: start
        ) ?? start
        return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(last.formatted(date: .abbreviated, time: .omitted))"
    }

    private func changeText(_ delta: Int) -> String {
        delta > 0 ? "+\(delta)" : "\(delta)"
    }
}
