import SwiftData
import SwiftUI

struct ArchivedHabitsView: View {
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    private var archivedHabits: [Habit] {
        habits.filter(\.isArchived)
    }

    var body: some View {
        Group {
            if archivedHabits.isEmpty {
                ContentUnavailableView(
                    L10n.string("archive.empty.title"),
                    systemImage: "archivebox",
                    description: Text(
                        L10n.string("archive.empty.description")
                    )
                )
            } else {
                List(archivedHabits) { habit in
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
                                    .foregroundStyle(
                                        Color(hex: habit.colorHex)
                                    )
                            }
                            .frame(width: 40, height: 40)
                            .accessibilityHidden(true)

                            Text(habit.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(L10n.string("archive.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
