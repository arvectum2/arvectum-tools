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

/// Read-only filtering of detached history rows, without touching SwiftData.
/// Today follows the user's calendar (DST-safe); other periods are rolling
/// calendar days relative to the time the list is evaluated.
enum NotificationHistoryFilter {
    enum Period: String, CaseIterable, Identifiable {
        case all, today, last7Days, last30Days
        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: pc("All time")
            case .today: pc("Today")
            case .last7Days: pc("Last 7 days")
            case .last30Days: pc("Last 30 days")
            }
        }
    }

    static func sources(in items: [NotificationHistoryItem]) -> [String] {
        Array(Set(items.map(\.sourceApp).filter { !$0.isEmpty }))
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    static func apply(
        _ items: [NotificationHistoryItem],
        query: String = "", source: String? = nil,
        period: Period = .all, now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [NotificationHistoryItem] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        // If the last record from a selected source was deleted, do not
        // trap the user in a permanently empty filtered view.
        let activeSource = source.flatMap { candidate in
            items.contains(where: { $0.sourceApp == candidate }) ? candidate : nil
        }
        let cutoff: Date?
        switch period {
        case .all: cutoff = nil
        case .today: cutoff = calendar.startOfDay(for: now)
        case .last7Days: cutoff = calendar.date(byAdding: .day, value: -7, to: now)
        case .last30Days: cutoff = calendar.date(byAdding: .day, value: -30, to: now)
        }
        return items.filter { item in
            if let activeSource, item.sourceApp != activeSource { return false }
            if let cutoff, item.receivedAt < cutoff { return false }
            return term.isEmpty || [item.sourceApp, item.titleText,
                                    item.subtitleText, item.bodyText]
                .contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }
}
