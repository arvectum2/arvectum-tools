import Foundation
import SwiftData

/// Detached presentation value. SwiftUI may keep a row or a navigation
/// destination alive while SwiftData invalidates a deleted @Model instance.
struct NotificationHistoryItem: Identifiable, Equatable {
    let id: UUID
    let sourceApp: String
    let titleText: String
    let subtitleText: String
    let bodyText: String
    let receivedAt: Date
    let duplicateCandidate: Bool

    init(_ model: CapturedNotification) {
        id = model.id
        sourceApp = model.sourceApp
        titleText = model.titleText
        subtitleText = model.subtitleText
        bodyText = model.bodyText
        receivedAt = model.receivedAt
        duplicateCandidate = model.duplicateCandidate
    }

    var shareText: String {
        var parts = [sourceApp]
        if !titleText.isEmpty { parts.append(titleText) }
        if !subtitleText.isEmpty { parts.append(subtitleText) }
        if !bodyText.isEmpty { parts.append(bodyText) }
        return parts.joined(separator: "\n")
    }
}

/// Delete by stable UUID, never by holding a model instance in a SwiftUI
/// navigation destination across an observation update.
@MainActor
enum NotificationHistoryDeletion {
    @discardableResult
    static func delete(id: UUID, in context: ModelContext) throws -> Bool {
        var descriptor = FetchDescriptor<CapturedNotification>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            return false  // A repeated delete must not touch another row.
        }
        context.delete(record)
        try context.save()
        return true
    }

    static func deleteAll(in context: ModelContext) throws {
        // Explicit record deletion avoids SwiftData's batch-delete path while
        // @Query and navigation destinations are observing the same store.
        let records = try context.fetch(FetchDescriptor<CapturedNotification>())
        for record in records {
            context.delete(record)
        }
        try context.save()
    }
}
