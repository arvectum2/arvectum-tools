import Foundation
import SwiftData

enum NotifyStore {
    static let modelContainer: ModelContainer = {
        let schema = Schema([
            CapturedNotification.self
        ])
        let configuration = ModelConfiguration(
            "ArvectumNotify",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Unable to create Arvectum Notify store: \(error)")
        }
    }()

    static let writer = NotifyPersistenceActor(
        modelContainer: modelContainer
    )
}

@ModelActor
actor NotifyPersistenceActor {
    func save(_ draft: NotificationCaptureDraft) throws -> UUID {
        var recentDescriptor = FetchDescriptor<CapturedNotification>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        recentDescriptor.fetchLimit = 50

        let recent = try modelContext.fetch(recentDescriptor)
        let matching = recent.filter { item in
            item.sourceApp == draft.sourceApp
                && item.titleText == draft.titleText
                && item.subtitleText == draft.subtitleText
                && item.bodyText == draft.bodyText
        }

        // Multiple notification automations may overlap during incremental
        // coverage refreshes. Their App Intents can arrive almost
        // simultaneously. Suppress that transport-level duplicate entirely
        // so the user sees one notification in PUSHKIN.
        if let existing = matching.first(where: {
            abs($0.capturedAt.timeIntervalSince(draft.capturedAt)) <= 2
        }) {
            return existing.id
        }

        // Keep the broader 10-second signal as diagnostics only. A genuine
        // repeated notification several seconds later should still be stored.
        let duplicate = matching.contains {
            abs($0.capturedAt.timeIntervalSince(draft.capturedAt)) <= 10
        }

        let record = CapturedNotification(
            sourceApp: draft.sourceApp,
            sourceBundleIdentifier: draft.sourceBundleIdentifier,
            titleText: draft.titleText,
            subtitleText: draft.subtitleText,
            bodyText: draft.bodyText,
            receivedAt: draft.receivedAt,
            capturedAt: draft.capturedAt,
            duplicateCandidate: duplicate,
            rawTitleText: draft.rawTitleText,
            rawSubtitleText: draft.rawSubtitleText,
            rawMessageText: draft.rawMessageText,
            normalizationMode: draft.normalizationMode,
            timestampSource: draft.timestampSource
        )

        modelContext.insert(record)
        try modelContext.save()
        return record.id
    }

    func deleteAll() throws {
        try modelContext.delete(model: CapturedNotification.self)
        try modelContext.save()
    }
}
