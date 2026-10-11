import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// An explicit, user-controlled JSON backup. No data is sent to Arvectum servers.
/// Files are plaintext; the user chooses a secure destination.
struct ChickMarkBackup: Codable {
    static let supportedVersion = 1
    let formatVersion: Int
    let createdAt: Date
    let habits: [HabitRecord]
    let checkIns: [CheckInRecord]
    let skips: [SkipRecord]
    let pauses: [PauseRecord]
    let mutations: [MutationRecord]
    let oneOffs: [OneOffRecord]
    // Optional for backwards-compatible imports of backups made before groups.
    var groups: [ChickMarkGroup]?

    struct HabitRecord: Codable {
        let id: UUID
        let name: String
        let symbolName: String
        let colorHex: String
        let createdAt: Date
        let isArchived: Bool
        let scheduleMask: Int
        let reminderEnabled: Bool
        let reminderHour: Int
        let reminderMinute: Int
        let pausedAt: Date?
        let weeklyTarget: Int
        let sortOrder: Int
    }

    struct CheckInRecord: Codable {
        let id: UUID
        let habitID: UUID
        let day: Date
        let dayKey: String?
        let createdAt: Date
    }

    struct SkipRecord: Codable {
        let id: UUID
        let habitID: UUID
        let day: Date
        let dayKey: String
        let createdAt: Date
    }

    struct PauseRecord: Codable {
        let id: UUID
        let habitID: UUID
        let startedAt: Date
        let startDayKey: String
        let endedAt: Date?
        let endDayKeyExclusive: String?
    }

    struct MutationRecord: Codable {
        let id: UUID
        let habitID: UUID
        let dayKey: String
        let updatedAt: Date
        let mutationID: UUID
    }

    struct OneOffRecord: Codable {
        let id: UUID
        let title: String
        let dueAt: Date
        let createdAt: Date
        let isCompleted: Bool
        let completedAt: Date?
    }

    func validate() throws {
        guard formatVersion == Self.supportedVersion else {
            throw BackupError.unsupportedVersion
        }
        guard !habits.contains(where: { $0.name.isEmpty }),
              !oneOffs.contains(where: { $0.title.isEmpty })
        else { throw BackupError.invalidData }
        guard Set(habits.map(\.id)).count == habits.count,
              Set(checkIns.map(\.id)).count == checkIns.count,
              Set(skips.map(\.id)).count == skips.count,
              Set(pauses.map(\.id)).count == pauses.count,
              Set(mutations.map(\.id)).count == mutations.count,
              Set(oneOffs.map(\.id)).count == oneOffs.count
        else { throw BackupError.invalidData }
        let habitIDs = Set(habits.map(\.id))
        guard checkIns.allSatisfy({ habitIDs.contains($0.habitID) }),
              skips.allSatisfy({ habitIDs.contains($0.habitID) }),
              pauses.allSatisfy({ habitIDs.contains($0.habitID) }),
              mutations.allSatisfy({ habitIDs.contains($0.habitID) })
        else { throw BackupError.invalidData }
    }
}

enum BackupError: LocalizedError {
    case unsupportedVersion
    case invalidData
    case unreadableDocument

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion: L10n.string("backup.error.version")
        case .invalidData: L10n.string("backup.error.invalid")
        case .unreadableDocument: L10n.string("backup.error.unreadable")
        }
    }
}

struct ChickMarkBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    var backup: ChickMarkBackup

    init(backup: ChickMarkBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw BackupError.unreadableDocument
        }
        backup = try JSONDecoder().decode(ChickMarkBackup.self, from: data)
        try backup.validate()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try backup.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(backup))
    }
}
