import AppIntents
import AppIntents
import Foundation

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
        let draft = NotificationCaptureDraft(
            sourceApp: sourceApp.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceBundleIdentifier: sourceBundleIdentifier?.nilIfBlank,
            titleText: notificationTitle?.trimmed ?? "",
            subtitleText: notificationSubtitle?.trimmed ?? "",
            bodyText: notificationMessage?.trimmed ?? "",
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
