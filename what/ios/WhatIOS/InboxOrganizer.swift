import Foundation

enum InboxFolder: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case archive = "Archive"

    var id: Self { self }
}

enum InboxDay: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"
    case earlier = "Earlier"

    var id: Self { self }
}

struct InboxDayGroup: Identifiable {
    let day: InboxDay
    let recordings: [RecordingEnvelope]
    var id: InboxDay { day }
}

/// Local-only filtering and calendar grouping; never scans audio or sends queries.
enum InboxOrganizer {
    static func recordings(
        _ items: [RecordingEnvelope],
        archivedIDs: Set<UUID>,
        folder: InboxFolder,
        query: String,
        transcripts: [UUID: String]
    ) -> [RecordingEnvelope] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { recording in
            let isArchived = archivedIDs.contains(recording.id)
            guard (folder == .archive) == isArchived else { return false }
            guard !needle.isEmpty else { return true }
            let text = transcripts[recording.id] ?? ""
            let date = DateFormatter.localizedString(
                from: recording.createdAt, dateStyle: .medium, timeStyle: .short
            )
            return text.localizedStandardContains(needle)
                || date.localizedStandardContains(needle)
        }.sorted {
            if $0.createdAt == $1.createdAt {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.createdAt > $1.createdAt
        }
    }

    static func groups(
        _ items: [RecordingEnvelope],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [InboxDayGroup] {
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let grouped = Dictionary(grouping: items) { recording -> InboxDay in
            if calendar.isDate(recording.createdAt, inSameDayAs: now) {
                return .today
            } else if calendar.isDate(recording.createdAt, inSameDayAs: yesterday) {
                return .yesterday
            }
            return .earlier
        }
        return InboxDay.allCases.compactMap { day in
            guard let recordings = grouped[day], !recordings.isEmpty else { return nil }
            return InboxDayGroup(day: day, recordings: recordings)
        }
    }
}
