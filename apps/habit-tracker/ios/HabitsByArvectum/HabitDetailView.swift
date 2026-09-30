import SwiftData
import SwiftUI

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]

    @Bindable var habit: Habit
    @State private var showingDeleteConfirmation = false
    @State private var showingEditHabit = false

    private var habitCheckIns: [HabitCheckIn] {
        checkIns.filter { $0.habitID == habit.id }
    }

    private var recentDays: [Date] {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)

        return (0..<35).compactMap {
            calendar.date(byAdding: .day, value: $0 - 34, to: today)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                identityCard
                statsCard
                historyCard
                archiveButton
                deleteButton
            }
            .padding(16)
        }
        .background(Color.habitsBackground)
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.string("habit.edit.action")) {
                    showingEditHabit = true
                }
            }
        }
        .sheet(isPresented: $showingEditHabit) {
            AddHabitView(habit: habit)
        }
        .confirmationDialog(
            L10n.string("detail.delete.title"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.string("common.delete"), role: .destructive, action: deleteHabit)
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(L10n.string("detail.delete.message"))
        }
    }

    private var identityCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex).opacity(0.16))
                Image(systemName: habit.symbolName)
                    .font(.title2)
                    .foregroundStyle(Color(hex: habit.colorHex))
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.title3.weight(.semibold))
                Text(scheduleDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if habit.reminderEnabled {
                    Label(reminderDescription, systemImage: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var statsCard: some View {
        HStack(spacing: 10) {
            stat(
                value: "\(HabitMetrics.currentStreak(habit: habit, checkIns: checkIns))",
                label: L10n.string("stats.streak"),
                systemImage: "flame.fill"
            )
            stat(
                value: "\(Int(HabitMetrics.completionRate(habit: habit, checkIns: checkIns) * 100))%",
                label: L10n.string("stats.completion"),
                systemImage: "chart.line.uptrend.xyaxis"
            )
            stat(
                value: "\(habitCheckIns.count)",
                label: L10n.string("stats.checkins"),
                systemImage: "checkmark.circle.fill"
            )
        }
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("detail.history.title"))
                .font(.headline)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 7),
                    count: 7
                ),
                spacing: 7
            ) {
                ForEach(recentDays, id: \.self) { date in
                    dayCell(date)
                }
            }

            Text(L10n.string("detail.history.hint"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var archiveButton: some View {
        Button {
            habit.isArchived.toggle()
            try? modelContext.save()
            Task {
                _ = await HabitReminderScheduler.sync(habit: habit)
            }
            if habit.isArchived { dismiss() }
        } label: {
            Label(
                habit.isArchived
                    ? L10n.string("detail.restore")
                    : L10n.string("detail.archive"),
                systemImage: habit.isArchived ? "tray.and.arrow.up" : "archivebox"
            )
            .frame(maxWidth: .infinity)
            .frame(height: 46)
        }
        .buttonStyle(.bordered)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirmation = true
        } label: {
            Label(L10n.string("detail.delete"), systemImage: "trash")
                .frame(maxWidth: .infinity)
                .frame(height: 46)
        }
        .buttonStyle(.bordered)
    }

    private func stat(
        value: String,
        label: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .foregroundStyle(Color(hex: habit.colorHex))
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.habitsSurface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func dayCell(_ date: Date) -> some View {
        let calendar = Calendar.autoupdatingCurrent
        let scheduled = habit.schedule.includes(date, calendar: calendar)
        let completed = HabitMetrics.isCompleted(
            habitID: habit.id,
            on: date,
            checkIns: checkIns,
            calendar: calendar
        )
        let beforeCreation = date < calendar.startOfDay(for: habit.createdAt)
        let future = date > calendar.startOfDay(for: .now)
        let enabled = scheduled && !beforeCreation && !future

        return Button {
            toggle(date)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(dayBackground(
                        scheduled: scheduled,
                        completed: completed,
                        disabled: beforeCreation || future
                    ))
                    .aspectRatio(1, contentMode: .fit)

                Text("\(calendar.component(.day, from: date))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(completed ? Color.arvectumNavy : .primary)
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(accessibilityLabel(for: date, completed: completed))
    }

    private func dayBackground(
        scheduled: Bool,
        completed: Bool,
        disabled: Bool
    ) -> Color {
        if completed { return Color(hex: habit.colorHex) }
        if disabled { return Color.secondary.opacity(0.04) }
        if scheduled { return Color.secondary.opacity(0.12) }
        return Color.secondary.opacity(0.05)
    }

    private func toggle(_ date: Date) {
        let calendar = Calendar.autoupdatingCurrent

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
            modelContext.insert(
                HabitCheckIn(
                    habitID: habit.id,
                    day: date,
                    calendar: calendar
                )
            )
        }
        try? modelContext.save()
    }

    private var scheduleDescription: String {
        if habit.schedule == .everyDay {
            return L10n.string("schedule.everyday")
        }
        if habit.schedule == .weekdays {
            return L10n.string("schedule.weekdays.description")
        }

        let labels: [(String, HabitSchedule)] = [
            (L10n.string("weekday.mon.short"), .monday),
            (L10n.string("weekday.tue.short"), .tuesday),
            (L10n.string("weekday.wed.short"), .wednesday),
            (L10n.string("weekday.thu.short"), .thursday),
            (L10n.string("weekday.fri.short"), .friday),
            (L10n.string("weekday.sat.short"), .saturday),
            (L10n.string("weekday.sun.short"), .sunday)
        ]
        return labels
            .filter { habit.schedule.contains($0.1) }
            .map(\.0)
            .joined(separator: ", ")
    }

    private var reminderDescription: String {
        let date = Calendar.autoupdatingCurrent.date(
            bySettingHour: habit.reminderHour,
            minute: habit.reminderMinute,
            second: 0,
            of: .now
        ) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private func accessibilityLabel(for date: Date, completed: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let status = completed
            ? L10n.string("status.completed")
            : L10n.string("status.notCompleted")
        return "\(formatter.string(from: date)), \(status)"
    }

    private func deleteHabit() {
        HabitReminderScheduler.remove(habitID: habit.id)
        for checkIn in habitCheckIns {
            modelContext.delete(checkIn)
        }
        modelContext.delete(habit)
        try? modelContext.save()
        dismiss()
    }
}
