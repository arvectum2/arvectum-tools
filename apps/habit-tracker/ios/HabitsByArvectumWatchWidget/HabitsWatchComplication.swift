import SwiftUI
import WidgetKit

struct HabitsWatchEntry: TimelineEntry {
    let date: Date
    let snapshot: HabitSyncSnapshot
}

struct HabitsWatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitsWatchEntry {
        HabitsWatchEntry(
            date: .now,
            snapshot: HabitSyncSnapshot(
                generatedAt: .now,
                dayKey: "2026-10-01",
                completedCount: 1,
                skippedCount: 0,
                totalCount: 3,
                habits: [
                    HabitSyncHabit(
                        id: UUID(),
                        name: "Reading",
                        symbolName: "book.fill",
                        colorHex: "8B5CF6",
                        completed: false,
                        skipped: false,
                        streak: 4
                    )
                ]
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (HabitsWatchEntry) -> Void
    ) {
        completion(
            HabitsWatchEntry(
                date: .now,
                snapshot: WatchComplicationBridge.loadSnapshot()
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<HabitsWatchEntry>) -> Void
    ) {
        let now = Date()
        let entry = HabitsWatchEntry(
            date: now,
            snapshot: WatchComplicationBridge.loadSnapshot()
        )
        let nextRefresh = Calendar.autoupdatingCurrent.date(
            byAdding: .minute,
            value: 15,
            to: now
        ) ?? now.addingTimeInterval(900)

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefresh)
            )
        )
    }
}

struct HabitsWatchComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HabitsWatchEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circular
        case .accessoryRectangular:
            rectangular
        case .accessoryInline:
            inline
        default:
            rectangular
        }
    }

    private var circular: some View {
        Gauge(value: entry.snapshot.progress) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            Text(progressText)
                .font(.caption2.monospacedDigit())
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel(L10n.string("watch.widget.title"))
        .accessibilityValue(progressText)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text(L10n.string("watch.widget.title"))
                    .font(.headline)
                Spacer(minLength: 4)
                Text(progressText)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }

            if let habit = nextUnresolvedHabit {
                Label(
                    L10n.format("watch.widget.next.format", habit.name),
                    systemImage: habit.symbolName
                )
                .font(.caption)
                .lineLimit(1)
            } else {
                Text(L10n.string("watch.widget.empty"))
                    .font(.caption)
                    .lineLimit(1)
            }
        }
    }

    private var inline: some View {
        Label {
            Text(
                L10n.format(
                    "watch.widget.inline.format",
                    entry.snapshot.resolvedCount,
                    entry.snapshot.totalCount
                )
            )
        } icon: {
            Image(systemName: "checkmark.circle.fill")
        }
    }

    private var nextUnresolvedHabit: HabitSyncHabit? {
        entry.snapshot.habits.first {
            !$0.completed && !$0.skipped
        }
    }

    private var progressText: String {
        "\(entry.snapshot.resolvedCount)/\(entry.snapshot.totalCount)"
    }
}

struct HabitsWatchComplication: Widget {
    let kind = "HabitsWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: HabitsWatchProvider()
        ) { entry in
            HabitsWatchComplicationView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName(
            L10n.string("watch.widget.title")
        )
        .description(
            L10n.string("watch.widget.description")
        )
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

@main
struct HabitsWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        HabitsWatchComplication()
    }
}

private enum L10n {
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
