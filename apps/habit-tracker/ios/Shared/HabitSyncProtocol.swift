import Foundation

enum HabitSyncProtocol {
    static let version = 2
    static let packetKey = "habits.sync.packet"
}

struct HabitSyncHabit: Codable, Hashable, Identifiable {
    let id: UUID
    var name: String
    var symbolName: String
    var colorHex: String
    var completed: Bool
    var skipped: Bool = false
    var streak: Int
    var weeklyTarget: Int? = nil
    var weeklyCount: Int? = nil
}

struct HabitSyncDayProjection: Codable, Hashable {
    var dayKey: String
    var habits: [HabitSyncHabit]

    var completedCount: Int {
        habits.filter(\.completed).count
    }

    var skippedCount: Int {
        habits.filter { !$0.completed && $0.skipped }.count
    }

    var totalCount: Int {
        habits.count
    }
}

struct HabitSyncSnapshot: Codable, Hashable {
    var protocolVersion: Int = HabitSyncProtocol.version
    var generatedAt: Date
    var dayKey: String
    var completedCount: Int
    var skippedCount: Int = 0
    var totalCount: Int
    var habits: [HabitSyncHabit]
    var acknowledgedCommandIDs: [UUID] = []
    var projectedDays: [HabitSyncDayProjection]? = nil

    static let empty = HabitSyncSnapshot(
        generatedAt: .distantPast,
        dayKey: "",
        completedCount: 0,
        skippedCount: 0,
        totalCount: 0,
        habits: []
    )
    var resolvedCount: Int {
        completedCount + skippedCount
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(resolvedCount) / Double(totalCount)
    }

    func snapshot(forDayKey key: String) -> HabitSyncSnapshot? {
        if dayKey == key {
            return self
        }
        guard let projection = projectedDays?.first(where: {
            $0.dayKey == key
        }) else {
            return nil
        }

        return HabitSyncSnapshot(
            protocolVersion: protocolVersion,
            generatedAt: generatedAt,
            dayKey: projection.dayKey,
            completedCount: projection.completedCount,
            skippedCount: projection.skippedCount,
            totalCount: projection.totalCount,
            habits: projection.habits,
            acknowledgedCommandIDs: acknowledgedCommandIDs,
            projectedDays: projectedDays
        )
    }
}

struct HabitCompletionCommand: Codable, Hashable, Identifiable {
    let id: UUID
    let habitID: UUID
    let dayKey: String
    let completed: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        habitID: UUID,
        dayKey: String,
        completed: Bool,
        createdAt: Date = .now
    ) {
        self.id = id
        self.habitID = habitID
        self.dayKey = dayKey
        self.completed = completed
        self.createdAt = createdAt
    }
}

enum HabitCompletionCommandQueue {
    static let maximumCount = 100

    static func appending(
        _ command: HabitCompletionCommand,
        to commands: [HabitCompletionCommand]
    ) -> [HabitCompletionCommand] {
        guard !commands.contains(where: { $0.id == command.id }) else {
            return commands
        }

        var compacted = commands.filter {
            !($0.habitID == command.habitID && $0.dayKey == command.dayKey)
        }
        compacted.append(command)

        if compacted.count > maximumCount {
            compacted.removeFirst(compacted.count - maximumCount)
        }
        return compacted
    }
}

enum HabitSyncPacketKind: String, Codable {
    case snapshot
    case setCompletion
    case requestSnapshot
}

struct HabitSyncPacket: Codable {
    let kind: HabitSyncPacketKind
    let snapshot: HabitSyncSnapshot?
    let command: HabitCompletionCommand?

    static func snapshot(_ snapshot: HabitSyncSnapshot) -> HabitSyncPacket {
        HabitSyncPacket(
            kind: .snapshot,
            snapshot: snapshot,
            command: nil
        )
    }

    static func setCompletion(
        _ command: HabitCompletionCommand
    ) -> HabitSyncPacket {
        HabitSyncPacket(
            kind: .setCompletion,
            snapshot: nil,
            command: command
        )
    }

    static let requestSnapshot = HabitSyncPacket(
        kind: .requestSnapshot,
        snapshot: nil,
        command: nil
    )
}

enum HabitSyncCodec {
    static func encode(_ packet: HabitSyncPacket) throws -> Data {
        try JSONEncoder().encode(packet)
    }

    static func decode(_ data: Data) throws -> HabitSyncPacket {
        try JSONDecoder().decode(HabitSyncPacket.self, from: data)
    }

    static func message(_ packet: HabitSyncPacket) throws -> [String: Any] {
        [
            HabitSyncProtocol.packetKey: try encode(packet)
        ]
    }

    static func packet(from message: [String: Any]) throws -> HabitSyncPacket {
        guard let data = message[HabitSyncProtocol.packetKey] as? Data else {
            throw HabitSyncCodecError.missingPacket
        }
        return try decode(data)
    }
}

enum HabitSyncCodecError: Error {
    case missingPacket
}

enum HabitSyncPayloadBudget {
    static let maxEncodedBytes = 48 * 1024
    static let maxWatchNameCharacters = 64

    static func watchName(_ name: String) -> String {
        String(name.prefix(maxWatchNameCharacters))
    }

    static func encodedSize(of snapshot: HabitSyncSnapshot) -> Int {
        (try? HabitSyncCodec.encode(.snapshot(snapshot)).count) ?? .max
    }

    static func fitted(
        _ source: HabitSyncSnapshot,
        maxEncodedBytes: Int = maxEncodedBytes
    ) -> HabitSyncSnapshot {
        var candidate = source

        while encodedSize(of: candidate) > maxEncodedBytes,
              candidate.projectedDays?.isEmpty == false {
            candidate.projectedDays?.removeLast()
        }

        if encodedSize(of: candidate) > maxEncodedBytes,
           candidate.acknowledgedCommandIDs.count > 10 {
            candidate.acknowledgedCommandIDs = Array(
                candidate.acknowledgedCommandIDs.suffix(10)
            )
        }

        return candidate
    }
}
