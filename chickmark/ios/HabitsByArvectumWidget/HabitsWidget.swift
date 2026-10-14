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
                snapshot: HabitWidgetBridge.loadCurrentSnapshot()
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
            snapshot: HabitWidgetBridge.loadCurrentSnapshot()
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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

            Group {
                if entry.snapshot.totalCount == 0 {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 44, weight: .ultraLight))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                } else {
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
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(WidgetL10n.string("widget.title"))
                    .accessibilityValue(
                        WidgetL10n.format("widget.inline.format",
                                          entry.snapshot.resolvedCount,
                                          entry.snapshot.totalCount)
                    )
                }
            }
            .frame(width: 70, height: 70)
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
            Text(
                entry.snapshot.totalCount == 0
                    ? WidgetL10n.string("widget.empty.small")
                    : summaryText
            )
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }

    private var accessoryCircularView: some View {
        Group {
            if entry.snapshot.totalCount == 0 {
                Image(systemName: "checkmark.circle")
                    .font(.headline)
                    .accessibilityLabel(WidgetL10n.string("widget.empty.small"))
            } else {
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
        }
    }

    private var accessoryRectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text(WidgetL10n.string("widget.title"))
                    .font(.headline)
                Spacer(minLength: 4)
                if entry.snapshot.totalCount > 0 {
                    Text(progressText)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
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
                if entry.snapshot.totalCount > 0 {
                    Text(progressText)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
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
                    ForEach(Array(mediumHabits.prefix(mediumRowLimit))) { habit in
                        habitRow(habit)
                    }
                }

                if entry.snapshot.habits.count > mediumRowLimit {
                    Text(
                        WidgetL10n.format(
                            "widget.more.format",
                            entry.snapshot.habits.count - mediumRowLimit
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
            Link(destination: HabitDeepLink.habitURL(habit.id)) {
                HStack(spacing: 8) {
                    Image(systemName: habit.symbolName)
                        .foregroundStyle(Color(hex: habit.colorHex))
                        .frame(width: 20)

                    Text(habit.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if let target = habit.dailyTarget,
                       let count = habit.dailyCount {
                        Text(habit.durationStepMinutes.map {
                            WidgetL10n.format("widget.duration.format", count * $0, target * $0)
                        } ?? "\(count)/\(target)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else if let target = habit.weeklyTarget,
                       let count = habit.weeklyCount {
                        Text("\(count)/\(target)")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else if habit.streak > 0 {
                        Label(String(habit.streak), systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 40)
                .contentShape(Rectangle())
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
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                WidgetL10n.format(
                    habit.completed
                        ? "widget.action.undo.format"
                        : "widget.action.complete.format",
                    habit.name
                )
            )
        }
        .frame(minHeight: 44)
    }

    /// At most two rows in medium widgets; accessibility sizes get one
    /// generous row to avoid clipping and tiny action hit areas.
    private var mediumRowLimit: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : 2
    }

    private var mediumHabits: [HabitWidgetHabit] {
        HabitWidgetPresentation.prioritized(entry.snapshot.habits)
    }

    private var nextUnresolvedHabit: HabitWidgetHabit? {
        entry.snapshot.habits.first {
            !$0.completed && !$0.skipped
        }
    }

    private var inlineText: String {
        if entry.snapshot.totalCount == 0 {
            return WidgetL10n.string("widget.empty.small")
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

struct HabitsTodayWidget: Widget {
    let kind = "HabitsTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: HabitsWidgetProvider()
        ) { entry in
            HabitsTodayWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(HabitDeepLink.todayURL)
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
