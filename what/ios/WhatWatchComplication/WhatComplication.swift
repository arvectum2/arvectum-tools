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
        Group {
            switch family {
            case .accessoryRectangular:
                HStack(spacing: 6) {
                    Image("WhatGlyph")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(CaptureBrand.name)
                            .font(.headline)
                        Text(CaptureBrand.text("Запись", "Record"))
                            .font(.caption2)
                    }
                }
            case .accessoryInline:
                Label {
                    Text(CaptureBrand.text("Ухват: запись", "UhWhat? Record"))
                } icon: {
                    Image("WhatGlyph")
                        .renderingMode(.template)
                }
            default:
                ZStack {
                    AccessoryWidgetBackground()
                    Image("WhatGlyph")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                }
            }
        }
        // A complication is a single tap surface. A Link can open the Watch
        // app without delivering the capture URL, resulting in a second tap.
        .widgetURL(captureURL)
        .containerBackground(.clear, for: .widget)
    }
}

struct WhatCaptureComplication: Widget {
    let kind = "WhatCaptureComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CaptureProvider()) { _ in
            CaptureComplicationView()
        }
        .configurationDisplayName(CaptureBrand.text("Запись в Ухвате", "Record with UhWhat?"))
        .description(CaptureBrand.text("Запись новой мысли с циферблата часов.", "Start a new thought from the watch face."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct WhatComplicationBundle: WidgetBundle {
    var body: some Widget {
        WhatCaptureComplication()
    }
}
