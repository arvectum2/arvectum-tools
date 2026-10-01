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
