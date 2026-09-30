import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]

    @State private var showingAddHabit = false

    private var activeToday: [Habit] {
        habits.filter {
            !$0.isArchived && $0.schedule.includes(.now)
        }
    }

    private var completedCount: Int {
        activeToday.filter { isCompleted($0, on: .now) }.count
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
                ToolbarItem(placement: .topBarTrailing) {
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
        }
    }

    private var todayContent: some View {
        ScrollView {
            VStack(spacing: 14) {
                TodaySummary(
                    completed: completedCount,
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
                                streak: HabitMetrics.currentStreak(
                                    habit: habit,
                                    checkIns: checkIns
                                ),
                                onToggle: { toggle(habit, on: .now) }
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

    private func toggle(_ habit: Habit, on date: Date) {
        let calendar = Calendar.autoupdatingCurrent

        if let existing = checkIns.first(where: {
            $0.habitID == habit.id &&
            calendar.isDate($0.day, inSameDayAs: date)
        }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                HabitCheckIn(habitID: habit.id, day: date)
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        try? modelContext.save()
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
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.string("today.title"))
                    .font(.headline)
                Spacer()
                Text(L10n.format("today.progress.format", completed, total))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
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
    let streak: Int
    let onToggle: () -> Void

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
                        if streak > 0 {
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
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(
                        completed ? Color(hex: habit.colorHex) : .secondary
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
    }
}
