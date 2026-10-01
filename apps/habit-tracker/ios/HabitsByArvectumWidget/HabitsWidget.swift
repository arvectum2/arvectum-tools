import AppIntents
import SwiftUI
import WidgetKit

struct HabitsWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: HabitWidgetSnapshot
}

struct HabitsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsWidgetEntry {
        HabitsWidgetEntry(
            date: .now,
            snapshot: HabitWidgetSnapshot(
                generatedAt: .now,
                dayKey: "2026-10-01",
                completedCount: 1,
                skippedCount: 0,
                totalCount: 3,
                habits: [
                    HabitWidgetHabit(
                        id: UUID(),
                        name: WidgetL10n.string("widget.preview.water"),
                        symbolName: "drop.fill",
                        colorHex: "43E5C5",
                        completed: true,
                        skipped: false,
                        streak: 4
                    ),
                    HabitWidgetHabit(
                        id: UUID(),
                        name: WidgetL10n.string("widget.preview.reading"),
                        symbolName: "book.fill",
                        colorHex: "8B5CF6",
                        completed: false,
                        skipped: false,
                        streak: 2
                    )
                ]
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (HabitsWidgetEntry) -> Void
    ) {
        completion(
            HabitsWidgetEntry(
                date: .now,
                snapshot: HabitWidgetBridge.loadSnapshot()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<HabitsWidgetEntry>) -> Void
    ) {
        let now = Date()
        let entry = HabitsWidgetEntry(
            date: now,
            snapshot: HabitWidgetBridge.loadSnapshot()
        )
        let calendar = Calendar.autoupdatingCurrent
        let nextDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: now)
        ) ?? now.addingTimeInterval(3600)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextDay.addingTimeInterval(5))
            )
        )
    }
}

struct HabitsTodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitsWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        case .accessoryInline:
            accessoryInlineView
        default:
            mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.18), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: entry.snapshot.progress)
                    .stroke(
                        Color(hex: "43E5C5"),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text(progressText)
                    .font(.headline.monospacedDigit())
            }
            .frame(width: 70, height: 70)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var accessoryCircularView: some View {
        Gauge(value: entry.snapshot.progress) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            Text(progressText)
                .font(.caption2.monospacedDigit())
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(WidgetL10n.string("widget.title"))
        .accessibilityValue(progressText)
    }

    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text(WidgetL10n.string("widget.title"))
                    .font(.headline)
                Spacer(minLength: 4)
                Text(progressText)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }

            if let habit = nextUnresolvedHabit {
                HStack(spacing: 5) {
                    Image(systemName: habit.symbolName)
                    Text(habit.name)
                        .lineLimit(1)
                }
                .font(.caption)
            } else {
                Text(summaryText)
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }

    private var accessoryInlineView: some View {
        Label {
            Text(inlineText)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                header
                Spacer()
                Text(progressText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }

            if entry.snapshot.habits.isEmpty {
                Spacer()
                Text(WidgetL10n.string("widget.empty"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                VStack(spacing: 5) {
                    ForEach(Array(entry.snapshot.habits.prefix(3))) { habit in
                        habitRow(habit)
                    }
                }

                if entry.snapshot.habits.count > 3 {
                    Text(
                        WidgetL10n.format(
                            "widget.more.format",
                            entry.snapshot.habits.count - 3
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var header: some View {
        Label(
            WidgetL10n.string("widget.title"),
            systemImage: "checkmark.circle.fill"
        )
        .font(.headline)
    }

    private func habitRow(_ habit: HabitWidgetHabit) -> some View {
        HStack(spacing: 8) {
            Image(systemName: habit.symbolName)
                .foregroundStyle(Color(hex: habit.colorHex))
                .frame(width: 20)

            Text(habit.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(1)

            Spacer(minLength: 4)

            if let target = habit.weeklyTarget,
               let count = habit.weeklyCount {
                Text("\(count)/\(target)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else if habit.streak > 0 {
                Label(String(habit.streak), systemImage: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button(
                intent: ToggleHabitWidgetIntent(
                    habitID: habit.id.uuidString,
                    dayKey: entry.snapshot.dayKey,
                    completed: !habit.completed
                )
            ) {
                Image(
                    systemName: habit.completed
                        ? "checkmark.circle.fill"
                        : (habit.skipped ? "minus.circle.fill" : "circle")
                )
                .font(.title3)
                .foregroundStyle(
                    habit.completed
                        ? Color(hex: habit.colorHex)
                        : .secondary
                )
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                habit.completed
                    ? WidgetL10n.string("widget.undo")
                    : WidgetL10n.string("widget.complete")
            )
        }
        .frame(minHeight: 32)
    }

    private var nextUnresolvedHabit: HabitWidgetHabit? {
        entry.snapshot.habits.first {
            !$0.completed && !$0.skipped
        }
    }

    private var inlineText: String {
        if entry.snapshot.totalCount == 0 {
            return WidgetL10n.string("widget.empty")
        }
        return WidgetL10n.format(
            "widget.inline.format",
            entry.snapshot.resolvedCount,
            entry.snapshot.totalCount
        )
    }

    private var progressText: String {
        "\(entry.snapshot.resolvedCount)/\(entry.snapshot.totalCount)"
    }

    private var summaryText: String {
        if entry.snapshot.totalCount == 0 {
            return WidgetL10n.string("widget.empty")
        }
        if entry.snapshot.resolvedCount == entry.snapshot.totalCount {
            return WidgetL10n.string("widget.allDone")
        }
        return WidgetL10n.format(
            "widget.remaining.format",
            entry.snapshot.totalCount - entry.snapshot.resolvedCount
        )
    }
}

struct ToggleHabitWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle habit"
    static var description = IntentDescription(
        "Mark or unmark a habit from the Habits widget."
    )

    @Parameter(title: "Habit ID")
    var habitID: String

    @Parameter(title: "Day")
    var dayKey: String

    @Parameter(title: "Completed")
    var completed: Bool

    init() {}

    init(
        habitID: String,
        dayKey: String,
        completed: Bool
    ) {
        self.habitID = habitID
        self.dayKey = dayKey
        self.completed = completed
    }

    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: habitID) else {
            return .result()
        }

        let command = HabitWidgetCommand(
            habitID: id,
            dayKey: dayKey,
            completed: completed
        )
        HabitWidgetBridge.appendCommand(command)
        HabitWidgetBridge.applyOptimistic(command)
        WidgetCenter.shared.reloadTimelines(
            ofKind: "HabitsTodayWidget"
        )
        return .result()
    }
}

struct HabitsTodayWidget: Widget {
    let kind = "HabitsTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: HabitsWidgetProvider()
        ) { entry in
            HabitsTodayWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName(
            WidgetL10n.string("widget.displayName")
        )
        .description(
            WidgetL10n.string("widget.description")
        )
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@main
struct HabitsWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitsTodayWidget()
    }
}

private enum WidgetL10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(
            format: string(key),
            locale: Locale.current,
            arguments: arguments
        )
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
