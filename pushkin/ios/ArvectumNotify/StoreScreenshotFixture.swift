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
        func localized(_ english: String, _ russian: String) -> String {
            StoreScreenshotTranslations.value(english, russian)
        }
        let samples: [CapturedNotification] = [
            CapturedNotification(
                sourceApp: localized("Messages", "Сообщения"),
                titleText: localized("Delivery update", "Статус доставки"),
                subtitleText: "",
                bodyText: localized("Your order will arrive between 18:00 and 19:00.", "Ваш заказ приедет с 18:00 до 19:00."),
                receivedAt: now.addingTimeInterval(-7 * 60),
                capturedAt: now.addingTimeInterval(-7 * 60)
            ),
            CapturedNotification(
                sourceApp: "Telegram",
                titleText: localized("Design team", "Команда дизайна"),
                subtitleText: "Maya",
                bodyText: localized("I sent the final mockups — take a look when you can.", "Отправила макеты — посмотри, пожалуйста."),
                receivedAt: now.addingTimeInterval(-24 * 60),
                capturedAt: now.addingTimeInterval(-24 * 60)
            ),
            CapturedNotification(
                sourceApp: localized("Mail", "Почта"),
                titleText: localized("Your booking is confirmed", "Бронирование подтверждено"),
                subtitleText: "",
                bodyText: localized("Confirmation #4821 · Thursday, 10:30", "Подтверждение №4821 · четверг, 10:30"),
                receivedAt: now.addingTimeInterval(-58 * 60),
                capturedAt: now.addingTimeInterval(-58 * 60)
            ),
            CapturedNotification(
                sourceApp: "WhatsApp Messenger",
                titleText: localized("Family", "Семья"),
                subtitleText: "",
                bodyText: localized("Don't forget the photos from yesterday 🙂", "Не забудь фотографии со вчерашнего дня 🙂"),
                receivedAt: now.addingTimeInterval(-2 * 60 * 60),
                capturedAt: now.addingTimeInterval(-2 * 60 * 60)
            ),
            CapturedNotification(
                sourceApp: "OZON",
                titleText: localized("Order ready for pickup", "Заказ готов к выдаче"),
                subtitleText: "",
                bodyText: localized("You can collect it until October 4.", "Заберите заказ до 4 октября."),
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
