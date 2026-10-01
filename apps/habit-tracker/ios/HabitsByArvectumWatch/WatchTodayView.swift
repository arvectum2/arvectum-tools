import SwiftUI

struct WatchTodayView: View {
    @EnvironmentObject private var syncStore: WatchHabitSyncStore

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if syncStore.snapshot.totalCount > 0 {
                    progressHeader
                }

                if syncStore.snapshot.habits.isEmpty {
                    emptyState
                } else {
                    ForEach(syncStore.snapshot.habits) { habit in
                        habitButton(habit)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle(WatchL10n.string("watch.today"))
        .onAppear {
            syncStore.refresh()
#if DEBUG
            syncStore.debugAutoToggleCachedFirstHabitIfRequested()
#endif
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 5) {
            ProgressView(
                value: Double(syncStore.snapshot.resolvedCount),
                total: Double(max(syncStore.snapshot.totalCount, 1))
            )
            .tint(.arvectumMint)

            Text(
                WatchL10n.format(
                    "watch.progress.format",
                    syncStore.snapshot.resolvedCount,
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
        Button {
            syncStore.toggle(habit)
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
    }
}
