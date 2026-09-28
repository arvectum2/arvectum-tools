import Foundation
import SwiftData

@Model
final class CapturedNotification {
    @Attribute(.unique) var id: UUID
    var sourceApp: String
    var sourceBundleIdentifier: String?
    var titleText: String
    var subtitleText: String
    var bodyText: String
    var receivedAt: Date
    var capturedAt: Date
    var duplicateCandidate: Bool
    var captureChannel: String

    init(
        id: UUID = UUID(),
        sourceApp: String,
        sourceBundleIdentifier: String? = nil,
        titleText: String,
        subtitleText: String,
        bodyText: String,
        receivedAt: Date,
        capturedAt: Date = .now,
        duplicateCandidate: Bool = false,
        captureChannel: String = "shortcuts-notification"
    ) {
        self.id = id
        self.sourceApp = sourceApp
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.bodyText = bodyText
        self.receivedAt = receivedAt
        self.capturedAt = capturedAt
        self.duplicateCandidate = duplicateCandidate
        self.captureChannel = captureChannel
    }
}

struct NotificationCaptureDraft: Sendable {
    let sourceApp: String
    let sourceBundleIdentifier: String?
    let titleText: String
    let subtitleText: String
    let bodyText: String
    let receivedAt: Date
    let capturedAt: Date
}
