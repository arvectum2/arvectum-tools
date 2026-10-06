import SwiftUI
import WidgetKit

private struct CaptureEntry: TimelineEntry {
    let date: Date
}

private struct CaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaptureEntry {
        CaptureEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CaptureEntry) -> Void) {
        completion(CaptureEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaptureEntry>) -> Void) {
        completion(Timeline(entries: [CaptureEntry(date: Date())], policy: .never))
    }
}

private struct CaptureComplicationView: View {
    @Environment(\.widgetFamily) private var family
    private let captureURL = URL(string: "what://capture")!

    var body: some View {
        Link(destination: captureURL) {
            switch family {
            case .accessoryRectangular:
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                    VStack(alignment: .leading, spacing: 1) {
                        Text("What?")
                            .font(.headline)
                        Text("Record")
                            .font(.caption2)
                    }
                }
            case .accessoryInline:
                Label("What? Record", systemImage: "mic.fill")
            default:
                ZStack {
                    AccessoryWidgetBackground()
                    Image(systemName: "mic.fill")
                        .font(.title2)
                }
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct WhatCaptureComplication: Widget {
    let kind = "WhatCaptureComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaptureProvider()) { _ in
            CaptureComplicationView()
        }
        .configurationDisplayName("Record with What?")
        .description("Start a new thought from the watch face.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct WhatComplicationBundle: WidgetBundle {
    var body: some Widget {
        WhatCaptureComplication()
    }
}
