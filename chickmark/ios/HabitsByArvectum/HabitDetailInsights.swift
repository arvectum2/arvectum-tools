import SwiftUI

extension HabitDetailView {
    var insightsCard: some View {
        let week = HabitInsights.window(
            habit: habit, checkIns: checkIns, skips: skips,
            pausePeriods: pausePeriods, days: 7
        )
        let month = HabitInsights.window(
            habit: habit, checkIns: checkIns, skips: skips,
            pausePeriods: pausePeriods, days: 30
        )

        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("insights.title"))
                .font(.headline)

            HStack(spacing: 12) {
                insight(week, title: L10n.string("insights.week"))
                insight(month, title: L10n.string("insights.month"))
            }
            Text(L10n.string("insights.note"))
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    func insight(_ window: HabitInsightWindow, title: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(Color.habitsSecondaryText)
            Text(window.eligible == 0 ? L10n.string("insights.noData") : "\(window.percent)%")
                .font(window.eligible == 0 ? .subheadline.weight(.semibold) : .title2.weight(.bold))
                .foregroundStyle(.primary)
            Text(L10n.format("insights.ratio", window.completed, window.eligible))
                .font(.caption)
            Text(L10n.format("insights.skipped", window.skipped))
                .font(.caption2)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    var weeklyInsightsCard: some View {
        let four = HabitInsights.weeklyWindow(
            habit: habit, checkIns: checkIns, skips: skips,
            pausePeriods: pausePeriods, previousWeeks: 4
        )
        let twelve = HabitInsights.weeklyWindow(
            habit: habit, checkIns: checkIns, skips: skips,
            pausePeriods: pausePeriods, previousWeeks: 12
        )
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("insights.weekly.title")).font(.headline)
            HStack(spacing: 12) {
                weeklyInsight(four, title: L10n.string("insights.fourWeeks"))
                weeklyInsight(twelve, title: L10n.string("insights.twelveWeeks"))
            }
            Text(L10n.string("insights.weekly.note"))
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    func weeklyInsight(
        _ result: HabitWeeklyInsight, title: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(Color.habitsSecondaryText)
            Text(result.eligible == 0
                 ? L10n.string("insights.noData") : "\(result.percent)%")
                .font(result.eligible == 0
                      ? .subheadline.weight(.semibold) : .title2.weight(.bold))
                .foregroundStyle(.primary)
            Text(L10n.format(
                "insights.weekly.ratio", result.achieved, result.eligible
            )).font(.caption)
            Text(L10n.format("insights.weekly.neutral", result.neutral))
                .font(.caption2)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    var intervalInsightsCard: some View {
        let month = HabitInsights.intervalWindow(
            habit: habit, checkIns: checkIns, days: 30
        )
        let quarter = HabitInsights.intervalWindow(
            habit: habit, checkIns: checkIns, days: 90
        )
        return VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("insights.interval.title")).font(.headline)
            HStack(spacing: 12) {
                intervalInsight(month, title: L10n.string("insights.month"))
                intervalInsight(quarter, title: L10n.string("insights.ninetyDays"))
            }
            Text(L10n.string("insights.interval.note"))
                .font(.caption)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    func intervalInsight(
        _ result: HabitIntervalInsight, title: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(Color.habitsSecondaryText)
            Text("\(result.occurrences)").font(.title2.weight(.bold))
            Text(L10n.string("insights.interval.occurrences")).font(.caption)
            Text(result.averageGapDays.map {
                L10n.format("insights.interval.average", $0)
            } ?? L10n.string("insights.interval.noGap"))
                .font(.caption2)
                .foregroundStyle(Color.habitsSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

}
