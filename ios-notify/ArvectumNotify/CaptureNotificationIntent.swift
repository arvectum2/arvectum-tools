import AppIntents
import Foundation

struct ShortcutNotificationPayload: Equatable {
    let titleText: String
    let subtitleText: String
    let bodyText: String

    init(title: String?, subtitle: String?, message: String?) {
        let title = title?.trimmed ?? ""
        let subtitle = subtitle?.trimmed ?? ""
        let message = message?.trimmed ?? ""

        // iOS 27's Notification trigger currently exposes one magic variable in
        // the action editor. When that value is coerced to String, real-world
        // Telegram notifications arrive as "title\nmessage". Preserve explicit
        // structured fields when Shortcuts provides them, otherwise normalize
        // this measured fallback into separate title/body fields.
        if subtitle.isEmpty, message.isEmpty {
            let parts = title.components(separatedBy: .newlines)
            let firstLine = parts.first?.trimmed ?? ""
            let remainingText = parts.dropFirst()
                .joined(separator: "\n")
                .trimmed

            if !firstLine.isEmpty, !remainingText.isEmpty {
                titleText = firstLine
                subtitleText = ""
                bodyText = remainingText
                return
            }
        }

        titleText = title
        subtitleText = subtitle
        bodyText = message
    }
}

struct CaptureNotificationIntent: AppIntent {
    static var title: LocalizedStringResource = "Archive Notification"
    static var description = IntentDescription(
        "Save an incoming notification to Arvectum Notify."
    )
    static var openAppWhenRun = false

    @Parameter(title: "Source app")
    var sourceApp: String

    @Parameter(title: "Title")
    var notificationTitle: String?

    @Parameter(title: "Subtitle")
    var notificationSubtitle: String?

    @Parameter(title: "Message")
    var notificationMessage: String?

    @Parameter(title: "Received at")
    var receivedAt: Date?

    @Parameter(title: "Source bundle identifier")
    var sourceBundleIdentifier: String?

    func perform() async throws -> some IntentResult {
        let capturedAt = Date()
        let payload = ShortcutNotificationPayload(
            title: notificationTitle,
            subtitle: notificationSubtitle,
            message: notificationMessage
        )
        let draft = NotificationCaptureDraft(
            sourceApp: sourceApp.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceBundleIdentifier: sourceBundleIdentifier?.nilIfBlank,
            titleText: payload.titleText,
            subtitleText: payload.subtitleText,
            bodyText: payload.bodyText,
            receivedAt: receivedAt ?? capturedAt,
            capturedAt: capturedAt
        )

        _ = try await NotifyStore.writer.save(draft)
        return .result()
    }
}

struct ArvectumNotifyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureNotificationIntent(),
            phrases: [
                "Archive a notification in \(.applicationName)"
            ],
            shortTitle: "Archive Notification",
            systemImageName: "tray.and.arrow.down"
        )
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
