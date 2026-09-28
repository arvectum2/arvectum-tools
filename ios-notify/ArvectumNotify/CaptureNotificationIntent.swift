import AppIntents
import Foundation

struct ShortcutNotificationPayload: Equatable {
    let rawTitleText: String?
    let rawSubtitleText: String?
    let rawMessageText: String?
    let titleText: String
    let subtitleText: String
    let bodyText: String
    let normalizationMode: String

    init(title: String?, subtitle: String?, message: String?) {
        rawTitleText = title
        rawSubtitleText = subtitle
        rawMessageText = message

        let title = title?.trimmed ?? ""
        let subtitle = subtitle?.trimmed ?? ""
        let message = message?.trimmed ?? ""

        // Measured on iOS 27: the Notification magic variable coerces to
        // "title\nmessage" for Telegram. Preserve structured fields whenever
        // Shortcuts supplies them and normalize only the measured fallback.
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
                normalizationMode = "multiline-title-body"
                return
            }

            titleText = title
            subtitleText = ""
            bodyText = ""
            normalizationMode = "title-only"
            return
        }

        titleText = title
        subtitleText = subtitle
        bodyText = message
        normalizationMode = "structured-fields"
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
            capturedAt: capturedAt,
            rawTitleText: payload.rawTitleText,
            rawSubtitleText: payload.rawSubtitleText,
            rawMessageText: payload.rawMessageText,
            normalizationMode: payload.normalizationMode,
            timestampSource: receivedAt == nil ? "capture-time-fallback" : "shortcut-provided"
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
