import SwiftData
import SwiftUI

struct ManageHabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    private var activeHabits: [Habit] {
        HabitOrdering.sorted(
            habits.filter { !$0.isArchived && !$0.isPaused }
        )
    }

    private var pausedHabits: [Habit] {
        HabitOrdering.sorted(
            habits.filter { !$0.isArchived && $0.isPaused }
        )
    }

    private var archivedHabits: [Habit] {
        HabitOrdering.sorted(habits.filter(\.isArchived))
    }

    var body: some View {
        Group {
            if habits.isEmpty {
                ContentUnavailableView(
                    L10n.string("manage.empty.title"),
                    systemImage: "tray",
                    description: Text(
                        L10n.string("manage.empty.description")
                    )
                )
            } else {
                List {
                    if !activeHabits.isEmpty {
                        Section {
                            ForEach(activeHabits) { habit in
                                habitLink(habit)
                            }
                            .onMove(perform: moveActiveHabits)
                        } header: {
                            Text(L10n.string("manage.active"))
                        } footer: {
                            if activeHabits.count > 1 {
                                Text(L10n.string("manage.reorder.hint"))
                            }
                        }
                    }

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
        .toolbar {
            if activeHabits.count > 1 {
                EditButton()
            }
        }
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

    private func moveActiveHabits(
        from source: IndexSet,
        to destination: Int
    ) {
        var reordered = activeHabits
        reordered.move(fromOffsets: source, toOffset: destination)

        for (index, habit) in reordered.enumerated() {
            habit.sortOrder = index
        }

        try? modelContext.save()
        HabitDataChangeNotifier.notify()
    }
}
