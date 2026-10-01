import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]
    @Query(sort: \HabitSkip.day) private var skips: [HabitSkip]
    @Query(sort: \HabitPausePeriod.startedAt) private var pausePeriods: [HabitPausePeriod]

    @State private var showingAddHabit = false

    private var activeToday: [Habit] {
        habits.filter {
            !$0.isArchived && !$0.isPaused && $0.schedule.includes(.now)
        }
    }

    private var archivedHabits: [Habit] {
        habits.filter(\.isArchived)
    }

    private var pausedHabits: [Habit] {
        habits.filter { !$0.isArchived && $0.isPaused }
    }

    private var resolvedCount: Int {
        activeToday.filter {
            isCompleted($0, on: .now) || isSkipped($0, on: .now)
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.habitsBackground.ignoresSafeArea()

                if habits.filter({ !$0.isArchived }).isEmpty {
                    firstHabitEmptyState
                } else {
                    todayContent
                }
            }
            .navigationTitle(L10n.string("today.title"))
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !archivedHabits.isEmpty || !pausedHabits.isEmpty {
                        NavigationLink {
                            ArchivedHabitsView()
                        } label: {
                            Image(systemName: "archivebox")
                        }
                        .accessibilityLabel(
                            L10n.string("manage.accessibility")
                        )
                    }

                    Button {
                        showingAddHabit = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel(L10n.string("habit.add.accessibility"))
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .task {
                backfillLegacyDayKeys()
                HabitWidgetCoordinator.shared.refresh()
#if DEBUG
                await HabitReminderScheduler.debugDumpIfRequested()
#endif
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    HabitWidgetCoordinator.shared.refresh()
                }
            }
        }
    }

    private var todayContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                TodaySummary(
                    completed: resolvedCount,
                    total: activeToday.count
                )

                if activeToday.isEmpty {
                    noHabitsTodayCard
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(activeToday) { habit in
                            HabitRow(
                                habit: habit,
                                completed: isCompleted(habit, on: .now),
                                skipped: isSkipped(habit, on: .now),
                                streak: HabitMetrics.currentStreak(
                                    habit: habit,
                                    checkIns: checkIns,
                                    skips: skips,
                                    pausePeriods: pausePeriods
                                ),
                                onToggle: { toggle(habit, on: .now) },
                                onSkip: { toggleSkip(habit, on: .now) }
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private var firstHabitEmptyState: some View {
        ContentUnavailableView {
            Label(L10n.string("today.empty.title"), systemImage: "checkmark.circle")
        } description: {
            Text(L10n.string("today.empty.description"))
        } actions: {
            Button(L10n.string("habit.create")) {
                showingAddHabit = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.arvectumMint)
            .foregroundStyle(Color.arvectumNavy)
        }
        .padding()
    }

    private var noHabitsTodayCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(L10n.string("today.none.title"))
                .font(.headline)
            Text(L10n.string("today.none.description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func isCompleted(_ habit: Habit, on date: Date) -> Bool {
        HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: checkIns
        )
    }

    private func isSkipped(_ habit: Habit, on date: Date) -> Bool {
        HabitMetrics.isSkipped(
            habitID: habit.id,
            on: date,
            skips: skips
        )
    }

    private func toggle(_ habit: Habit, on date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)

        if let existing = checkIns.first(where: {
            $0.habitID == habit.id &&
            HabitDayKey.matches(
                $0,
                on: date,
                calendar: calendar
            )
        }) {
            modelContext.delete(existing)
        } else {
            if let skip = skips.first(where: {
                $0.habitID == habit.id && $0.dayKey == key
            }) {
                modelContext.delete(skip)
            }

            modelContext.insert(
                HabitCheckIn(
                    habitID: habit.id,
                    day: date,
                    calendar: calendar
                )
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func toggleSkip(_ habit: Habit, on date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)

        if let existingSkip = skips.first(where: {
            $0.habitID == habit.id && $0.dayKey == key
        }) {
            modelContext.delete(existingSkip)
        } else {
            if let existingCheckIn = checkIns.first(where: {
                $0.habitID == habit.id &&
                HabitDayKey.matches(
                    $0,
                    on: date,
                    calendar: calendar
                )
            }) {
                modelContext.delete(existingCheckIn)
            }

            modelContext.insert(
                HabitSkip(
                    habitID: habit.id,
                    day: date,
                    calendar: calendar
                )
            )
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func backfillLegacyDayKeys() {
        let calendar = Calendar.autoupdatingCurrent
        var changed = false

        for checkIn in checkIns where checkIn.dayKey == nil {
            checkIn.dayKey = HabitDayKey.make(
                for: checkIn.day,
                calendar: calendar
            )
            changed = true
        }

        if changed {
            try? modelContext.save()
        }
    }
}

private struct TodaySummary: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("today.title"))
                        .font(.headline)
                    Text(L10n.format("today.progress.format", completed, total))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.string("today.title"))
                        .font(.headline)
                    Spacer()
                    Text(L10n.format("today.progress.format", completed, total))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress)
                .tint(Color.arvectumMint)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct HabitRow: View {
    let habit: Habit
    let completed: Bool
    let skipped: Bool
    let streak: Int
    let onToggle: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                HabitDetailView(habit: habit)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: habit.colorHex).opacity(0.16))
                        Image(systemName: habit.symbolName)
                            .font(.headline)
                            .foregroundStyle(Color(hex: habit.colorHex))
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(habit.name)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        if skipped {
                            Label(
                                L10n.string("habit.skipped.today"),
                                systemImage: "minus.circle.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else if streak > 0 {
                            Label(
                                L10n.format("habit.streak.format", streak),
                                systemImage: "flame.fill"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else {
                            Text(L10n.string("habit.streak.start"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 4)

            Button(action: onToggle) {
                Image(
                    systemName: completed
                        ? "checkmark.circle.fill"
                        : (skipped ? "minus.circle.fill" : "circle")
                )
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(
                    completed
                        ? Color(hex: habit.colorHex)
                        : (skipped ? Color.arvectumOrange : .secondary)
                )
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                completed
                    ? L10n.string("habit.undo")
                    : L10n.string("habit.complete")
            )
        }
        .padding(14)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 18))
        .contextMenu {
            Button(action: onSkip) {
                Label(
                    skipped
                        ? L10n.string("habit.skip.undo")
                        : L10n.string("habit.skip.today"),
                    systemImage: skipped
                        ? "arrow.uturn.backward"
                        : "forward.end"
                )
            }
        }
        .accessibilityAction(
            named: Text(
                skipped
                    ? L10n.string("habit.skip.undo")
                    : L10n.string("habit.skip.today")
            )
        ) {
            onSkip()
        }
    }
}
