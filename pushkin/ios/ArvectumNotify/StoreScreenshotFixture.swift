#if DEBUG
import Foundation
import SwiftData

@MainActor
enum StoreScreenshotFixture {
    static func installIfRequested(
        into context: ModelContext
    ) {
        let process = ProcessInfo.processInfo
        guard process.arguments.contains("--store-screenshot-fixture")
                || process.environment[
                    "PUSHKIN_STORE_SCREENSHOT_FIXTURE"
                ] == "1"
        else {
            return
        }

        try? context.delete(model: CapturedNotification.self)

        let now = Date()
        let samples: [CapturedNotification] = [
            CapturedNotification(
                sourceApp: "Messages",
                titleText: "Delivery update",
                subtitleText: "",
                bodyText: "Your order will arrive between 18:00 and 19:00.",
                receivedAt: now.addingTimeInterval(-7 * 60),
                capturedAt: now.addingTimeInterval(-7 * 60)
            ),
            CapturedNotification(
                sourceApp: "Telegram",
                titleText: "Design team",
                subtitleText: "Maya",
                bodyText: "I sent the final mockups — take a look when you can.",
                receivedAt: now.addingTimeInterval(-24 * 60),
                capturedAt: now.addingTimeInterval(-24 * 60)
            ),
            CapturedNotification(
                sourceApp: "Mail",
                titleText: "Your booking is confirmed",
                subtitleText: "",
                bodyText: "Confirmation #4821 · Thursday, 10:30",
                receivedAt: now.addingTimeInterval(-58 * 60),
                capturedAt: now.addingTimeInterval(-58 * 60)
            ),
            CapturedNotification(
                sourceApp: "WhatsApp Messenger",
                titleText: "Family",
                subtitleText: "",
                bodyText: "Don't forget the photos from yesterday 🙂",
                receivedAt: now.addingTimeInterval(-2 * 60 * 60),
                capturedAt: now.addingTimeInterval(-2 * 60 * 60)
            ),
            CapturedNotification(
                sourceApp: "OZON",
                titleText: "Order ready for pickup",
                subtitleText: "",
                bodyText: "You can collect it until October 4.",
                receivedAt: now.addingTimeInterval(-5 * 60 * 60),
                capturedAt: now.addingTimeInterval(-5 * 60 * 60)
            )
        ]

        for item in samples {
            context.insert(item)
        }
        try? context.save()
    }
}
#endif
