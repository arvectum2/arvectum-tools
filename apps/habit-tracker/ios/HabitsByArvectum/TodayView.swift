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
    @State private var undoOffer: CompletionUndoOffer?

    private var activeToday: [Habit] {
        HabitOrdering.sorted(
            habits.filter {
                !$0.isArchived && !$0.isPaused && HabitFrequency.isDue(
                    habit: $0,
                    on: .now,
                    checkIns: checkIns,
                    skips: skips,
                    pausePeriods: pausePeriods
                )
            }
        )
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
                    if !habits.isEmpty {
                        NavigationLink {
                            ManageHabitsView()
                        } label: {
                            Image(systemName: "line.3.horizontal")
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
            .overlay(alignment: .bottom) {
                if let undoOffer {
                    CompletionUndoToast {
                        undoCompletion(undoOffer)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                registerForegroundLaunchIfNeeded()
                backfillLegacyDayKeys()
                await HabitReminderCoordinator.shared.refreshNow()
                HabitWidgetCoordinator.shared.refresh()
#if DEBUG
                await HabitReminderScheduler.debugDumpIfRequested()
#endif
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    registerForegroundLaunchIfNeeded()
                    HabitReminderCoordinator.shared.refresh()
                    HabitWidgetCoordinator.shared.refresh()
                }
            }
        }
    }

    private var todayContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                if activeToday.isEmpty {
                    noHabitsTodayCard
                } else {
                    TodaySummary(
                        completed: resolvedCount,
                        total: activeToday.count
                    )

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
                                weeklyCount: HabitFrequency.weeklyCompletionCount(
                                    habit: habit,
                                    containing: .now,
                                    checkIns: checkIns
                                ),
                                weeklyTarget: HabitFrequency.effectiveWeeklyTarget(
                                    habit: habit,
                                    containing: .now,
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

    private func registerForegroundLaunchIfNeeded() {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else {
            return
        }
        HabitAdEligibilityStore.shared.registerForegroundLaunchOnce()
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
        let desiredState = !isCompleted(habit, on: date)

        let changed = HabitCompletionMutation.setCompletion(
            habitID: habit.id,
            dayKey: key,
            completed: desiredState,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID(),
            calendar: calendar
        )

        if desiredState && changed {
            HabitAdEligibilityStore.shared.registerSuccessfulCheckOff()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showUndo(for: habit.id, dayKey: key)
        } else if undoOffer?.habitID == habit.id {
            withAnimation { undoOffer = nil }
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }

    private func showUndo(for habitID: UUID, dayKey: String) {
        let offer = CompletionUndoOffer(
            id: UUID(),
            habitID: habitID,
            dayKey: dayKey
        )
        withAnimation(.snappy) {
            undoOffer = offer
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard undoOffer?.id == offer.id else { return }
            withAnimation(.snappy) {
                undoOffer = nil
            }
        }
    }

    private func undoCompletion(_ offer: CompletionUndoOffer) {
        _ = HabitCompletionMutation.setCompletion(
            habitID: offer.habitID,
            dayKey: offer.dayKey,
            completed: false,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID()
        )
        try? modelContext.save()
        HabitDataChangeNotifier.notify()
        withAnimation(.snappy) {
            undoOffer = nil
        }
    }

    private func toggleSkip(_ habit: Habit, on date: Date) {
        let calendar = Calendar.autoupdatingCurrent
        let key = HabitDayKey.make(for: date, calendar: calendar)
        let desiredState = !isSkipped(habit, on: date)

        _ = HabitSkipMutation.setSkipped(
            habitID: habit.id,
            dayKey: key,
            skipped: desiredState,
            context: modelContext,
            mutationAt: .now,
            mutationID: UUID(),
            calendar: calendar
        )

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
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.format("today.progress.format", completed, total))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            ProgressView(value: progress)
                .tint(Color.arvectumMint)
                .scaleEffect(x: 1, y: 1.5)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

private struct HabitRow: View {
    let habit: Habit
    let completed: Bool
    let skipped: Bool
    let streak: Int
    let weeklyCount: Int
    let weeklyTarget: Int
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
                        } else if habit.usesFlexibleWeeklyTarget {
                            Label(
                                L10n.format(
                                    "habit.weekly.progress.format",
                                    weeklyCount,
                                    weeklyTarget
                                ),
                                systemImage: "calendar.badge.checkmark"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        } else if streak > 0 {
                            Label(
                                L10n.streak(streak),
                                systemImage: "flame.fill"
                            )
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
                .symbolEffect(.bounce, value: completed)
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
