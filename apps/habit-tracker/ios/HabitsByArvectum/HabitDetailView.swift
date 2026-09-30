import SwiftData
import SwiftUI

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitCheckIn.day) private var checkIns: [HabitCheckIn]

    @Bindable var habit: Habit
    @State private var showingDeleteConfirmation = false

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
        .confirmationDialog(
            "Удалить привычку?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Удалить", role: .destructive, action: deleteHabit)
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("История выполнения этой привычки тоже будет удалена.")
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
                label: "серия",
                systemImage: "flame.fill"
            )
            stat(
                value: "\(Int(HabitMetrics.completionRate(habit: habit, checkIns: checkIns) * 100))%",
                label: "выполнено",
                systemImage: "chart.line.uptrend.xyaxis"
            )
            stat(
                value: "\(habitCheckIns.count)",
                label: "отметок",
                systemImage: "checkmark.circle.fill"
            )
        }
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Последние 5 недель")
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

            Text("Нажмите на прошедший день, чтобы исправить отметку.")
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
            if habit.isArchived { dismiss() }
        } label: {
            Label(
                habit.isArchived ? "Вернуть из архива" : "Архивировать",
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
            Label("Удалить привычку", systemImage: "trash")
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
            calendar.isDate($0.day, inSameDayAs: date)
        }) {
            modelContext.delete(existing)
        } else {
            modelContext.insert(
                HabitCheckIn(habitID: habit.id, day: date)
            )
        }
        try? modelContext.save()
    }

    private var scheduleDescription: String {
        if habit.schedule == .everyDay { return "Каждый день" }
        if habit.schedule == .weekdays { return "По будням" }

        let labels: [(String, HabitSchedule)] = [
            ("Пн", .monday), ("Вт", .tuesday), ("Ср", .wednesday),
            ("Чт", .thursday), ("Пт", .friday), ("Сб", .saturday),
            ("Вс", .sunday)
        ]
        return labels
            .filter { habit.schedule.contains($0.1) }
            .map(\.0)
            .joined(separator: ", ")
    }

    private func accessibilityLabel(for date: Date, completed: Bool) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: date)), \(completed ? "выполнено" : "не выполнено")"
    }

    private func deleteHabit() {
        for checkIn in habitCheckIns {
            modelContext.delete(checkIn)
        }
        modelContext.delete(habit)
        try? modelContext.save()
        dismiss()
    }
}
