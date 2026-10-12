import SwiftUI

struct WatchTodayView: View {
    @EnvironmentObject private var syncStore: WatchHabitSyncStore
    @State private var locallyVerified: Set<UUID> = []
    @State private var userOverridden: Set<UUID> = []
    private var resolvedCount: Int {
        // totalCount can include habits omitted from the compact Watch list.
        // Start with the authoritative snapshot counts, then add only
        // locally verified HealthKit habits not yet completed by the phone.
        let snapshot = syncStore.snapshot
        let newlyVerified = snapshot.habits.filter {
            locallyVerified.contains($0.id) &&
            !userOverridden.contains($0.id) &&
            !$0.completed && !$0.skipped
        }.count
        return min(
            max(0, snapshot.totalCount),
            max(0, snapshot.completedCount + snapshot.skippedCount + newlyVerified)
        )
    }

    private var verifiedHabits: [HabitSyncHabit] {
        syncStore.snapshot.habits.map { original in
            var habit = original
            if locallyVerified.contains(habit.id) && !userOverridden.contains(habit.id) {
                habit.completed = true
            }
            return habit
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if syncStore.snapshot.totalCount > 0 {
                    progressHeader
                }

                if syncStore.snapshot.habits.isEmpty {
                    emptyState
                } else {
                    ForEach(verifiedHabits) { habit in
                        habitButton(habit)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(WatchL10n.string("watch.today"))
        .task(id: syncStore.snapshot.generatedAt) {
            locallyVerified = await WatchHealthEvaluator.qualifyingIDs(for: syncStore.snapshot.habits)
        }
        .onChange(of: syncStore.snapshot.dayKey) { oldDay, newDay in
            guard oldDay != newDay else { return }
            // A manual override is valid for one day only. A cached Watch
            // view can survive midnight and must not suppress the next day's
            // legitimate HealthKit auto-completion.
            userOverridden.removeAll()
            locallyVerified.removeAll()
        }
        .task {
            // Re-evaluate cached snapshots when the date changes while the
            // Watch app remains on screen. Sleep until shortly after midnight
            // instead of polling WatchConnectivity every minute.
            while !Task.isCancelled {
                let calendar = Calendar.autoupdatingCurrent
                let start = calendar.startOfDay(for: .now)
                let nextDay = calendar.date(byAdding: .day, value: 1, to: start)
                    ?? Date.now.addingTimeInterval(86_400)
                let delay = max(30, nextDay.timeIntervalSinceNow + 2)
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { break }
                syncStore.refresh()
            }
        }
        .onAppear {
            syncStore.refresh()
#if DEBUG
            syncStore.debugAutoToggleCachedFirstHabitIfRequested()
            syncStore.debugStressToggleCachedFirstHabitIfRequested()
#endif
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 5) {
            GeometryReader { geometry in
                let fraction = min(
                    max(CGFloat(resolvedCount) / CGFloat(max(syncStore.snapshot.totalCount, 1)), 0),
                    1
                )
                Capsule()
                    .fill(Color.secondary.opacity(0.22))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(Color.arvectumMint)
                            .frame(width: geometry.size.width * fraction)
                    }
            }
            .frame(height: 6)
            .accessibilityHidden(true)

            Text(
                WatchL10n.format(
                    "watch.progress.format",
                    resolvedCount,
                    syncStore.snapshot.totalCount
                )
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(WatchL10n.string("watch.empty"))
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }

    private func habitButton(_ habit: HabitSyncHabit) -> some View {
        VStack(spacing: 3) {
        Button {
            if locallyVerified.contains(habit.id) && !userOverridden.contains(habit.id) {
                userOverridden.insert(habit.id)
                syncStore.toggle(habit, desiredStateOverride: false)
            } else {
                syncStore.toggle(habit)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: habit.symbolName)
                    .font(.body)
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(2)

                    if habit.skipped {
                        Text(WatchL10n.string("watch.skipped"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if habit.dailyTarget != nil && habit.dailyCount != nil {
                        // Progress is already centered between the +/- controls
                        // below. Repeating it here wastes scarce watch space.
                        EmptyView()
                    } else if let target = habit.weeklyTarget,
                              let count = habit.weeklyCount {
                        Text(
                            WatchL10n.format(
                                "watch.weekly.format",
                                count,
                                target
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    } else if habit.streak > 0 {
                        Text(
                            WatchL10n.format(
                                "watch.streak.format",
                                habit.streak
                            )
                        )
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 2)

                Image(
                    systemName: habit.completed
                        ? "checkmark.circle.fill"
                        : (habit.skipped ? "minus.circle.fill" : "circle")
                )
                .font(.title3)
                .symbolEffect(.bounce, value: habit.completed)
                .foregroundStyle(
                    habit.completed
                        ? Color(hex: habit.colorHex)
                        : (habit.skipped ? .orange : .secondary)
                )
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(habit.name)
        .accessibilityValue(
            habit.completed
                ? WatchL10n.string("watch.completed")
                : (
                    habit.skipped
                        ? WatchL10n.string("watch.skipped")
                        : WatchL10n.string("watch.notCompleted")
                )
        )
        .accessibilityHint(
            habit.completed
                ? WatchL10n.string("watch.undoHint")
                : WatchL10n.string("watch.completeHint")
        )
        if let target = habit.dailyTarget,
           let count = habit.dailyCount, target > 1 {
            HStack(spacing: 10) {
                Button {
                    syncStore.adjust(habit, by: -1)
                } label: {
                    Image(systemName: "minus.circle")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(count == 0)
                .accessibilityLabel(WatchL10n.string("watch.step.remove"))

                Text("\(count)/\(target)")
                    .font(.caption2.monospacedDigit())
                    .accessibilityLabel(
                        WatchL10n.format("watch.checkins.progress.format", count, target)
                    )
                    .accessibilityIdentifier("watch.checkins.progress")

                Button {
                    syncStore.adjust(habit, by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .disabled(count == target)
                .accessibilityLabel(WatchL10n.string("watch.step.add"))
            }
            .buttonStyle(.plain)
        }
        }
    }
}
