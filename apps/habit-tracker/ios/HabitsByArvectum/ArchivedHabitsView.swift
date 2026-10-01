import SwiftData
import SwiftUI

struct ArchivedHabitsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    private var pausedHabits: [Habit] {
        habits.filter { !$0.isArchived && $0.isPaused }
    }

    private var archivedHabits: [Habit] {
        habits.filter(\.isArchived)
    }

    var body: some View {
        Group {
            if pausedHabits.isEmpty && archivedHabits.isEmpty {
                ContentUnavailableView(
                    L10n.string("manage.empty.title"),
                    systemImage: "tray",
                    description: Text(
                        L10n.string("manage.empty.description")
                    )
                )
            } else {
                List {
                    if !pausedHabits.isEmpty {
                        Section(L10n.string("manage.paused")) {
                            ForEach(pausedHabits) { habit in
                                habitLink(habit)
                            }
                        }
                    }

                    if !archivedHabits.isEmpty {
                        Section(L10n.string("archive.title")) {
                            ForEach(archivedHabits) { habit in
                                habitLink(habit)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(L10n.string("manage.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func habitLink(_ habit: Habit) -> some View {
        NavigationLink {
            HabitDetailView(habit: habit)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            Color(hex: habit.colorHex)
                                .opacity(0.16)
                        )
                    Image(systemName: habit.symbolName)
                        .foregroundStyle(Color(hex: habit.colorHex))
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    if habit.isPaused && !habit.isArchived {
                        Text(L10n.string("manage.paused"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
