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

    // Optional Phase 0 diagnostics. Optional fields keep existing SwiftData
    // stores lightweight-migratable when the spike evolves.
    var rawTitleText: String?
    var rawSubtitleText: String?
    var rawMessageText: String?
    var normalizationMode: String?
    var timestampSource: String?

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
        captureChannel: String = "shortcuts-notification",
        rawTitleText: String? = nil,
        rawSubtitleText: String? = nil,
        rawMessageText: String? = nil,
        normalizationMode: String? = nil,
        timestampSource: String? = nil
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
        self.rawTitleText = rawTitleText
        self.rawSubtitleText = rawSubtitleText
        self.rawMessageText = rawMessageText
        self.normalizationMode = normalizationMode
        self.timestampSource = timestampSource
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
    var rawTitleText: String? = nil
    var rawSubtitleText: String? = nil
    var rawMessageText: String? = nil
    var normalizationMode: String? = nil
    var timestampSource: String? = nil
}
