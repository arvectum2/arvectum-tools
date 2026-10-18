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
    @Environment(\.widgetRenderingMode) private var renderingMode
    private let captureURL = WatchCaptureRouting.captureURL

    /// Show the actual Watch app icon in full-color rendering mode. On watch
    /// faces that force tint, draw the same vector mark as the app icon.
    /// A template-rendered 1024px bitmap can become a blank square there.
    @ViewBuilder
    private func mark(size: CGFloat) -> some View {
        if renderingMode == .fullColor {
            Image("WhatComplicationIcon")
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .accessibilityHidden(true)
        } else {
            WhatComplicationMark()
                .fill(.primary)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                HStack(spacing: 6) {
                    mark(size: 27)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(CaptureBrand.name)
                            .font(.headline)
                        Text(CaptureBrand.text("Запись", "Record"))
                            .font(.caption2)
                    }
                }
            case .accessoryInline:
                HStack(spacing: 4) {
                    mark(size: 16)
                    Text(CaptureBrand.text("Ухват: запись", "UhWhat? Record"))
                }
            case .accessoryCircular, .accessoryCorner:
                ZStack {
                    AccessoryWidgetBackground()
                    mark(size: 46)
                }
            default:
                mark(size: 38)
            }
        }
        .accessibilityLabel(CaptureBrand.text("Ухват. Начать запись", "UhWhat?. Start recording"))
        // Keep widgetURL + the on-foreground autostart policy: physical Watch
        // hardware sometimes opens the app without forwarding this URL.
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
        .configurationDisplayName(CaptureBrand.text("Запись в Ухват", "Record with UhWhat?"))
        .description(CaptureBrand.text("Запись новой мысли с циферблата часов.", "Start a new thought from the watch face."))
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

@main
struct WhatComplicationBundle: WidgetBundle {
    var body: some Widget {
        WhatCaptureComplication()
    }
}
