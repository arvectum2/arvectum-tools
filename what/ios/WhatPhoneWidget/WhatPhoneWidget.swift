import SwiftUI
import WidgetKit

private struct RecordEntry: TimelineEntry {
    let date: Date
}

private struct RecordProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecordEntry {
        RecordEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (RecordEntry) -> Void) {
        completion(RecordEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecordEntry>) -> Void) {
        completion(Timeline(entries: [RecordEntry(date: Date())], policy: .never))
    }
}

private struct RecordWidgetView: View {
    @Environment(\.widgetFamily) private var family
    private let recordURL = URL(string: "whatp2aqa://record")!

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(CaptureBrand.name).font(.headline)
                        Text(CaptureBrand.text("Записать мысль", "Record thought")).font(.caption2)
                    }
                    Spacer(minLength: 0)
                }
            case .systemMedium:
                HStack(spacing: 14) {
                    Image(systemName: "mic.circle.fill").font(.system(size: 44))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CaptureBrand.name).font(.headline)
                        Text(CaptureBrand.text("Нажми и говори", "Tap to record an idea")).font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            default:
                VStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill").font(.system(size: 42))
                    Text(CaptureBrand.text("Запись", "Record")).font(.headline)
                    Text(CaptureBrand.name).font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.primary)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(recordURL)
        .accessibilityLabel(CaptureBrand.text("Открыть Ухват и начать запись", "Open UhWhat? and start voice recording"))
    }
}

private struct WhatPhoneRecordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WhatPhoneRecord", provider: RecordProvider()) { _ in
            RecordWidgetView()
        }
        .configurationDisplayName(CaptureBrand.text("Запись в Ухвате", "Record with UhWhat?"))
        .description(CaptureBrand.text("Откройте Ухват и сразу запишите мысль на iPhone.", "Open UhWhat? and immediately start a voice note on your iPhone."))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

@main
struct WhatPhoneWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhatPhoneRecordWidget()
    }
}
