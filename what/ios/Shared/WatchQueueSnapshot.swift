import Foundation

/// A *last-reported* Watch queue count, never a live connectivity guarantee.
/// WCSession.applicationContext can be coalesced and delivered later.
struct WatchQueueSnapshot: Equatable {
    static let contextType = "what.watch.queue.v1"
    let pendingCount: Int
    let updatedAt: Date

    var context: [String: Any] {
        [
            TransferMetadataKey.type: Self.contextType,
            "pendingCount": pendingCount,
            "updatedAt": updatedAt.timeIntervalSince1970
        ]
    }

    init(pendingCount: Int, updatedAt: Date) {
        self.pendingCount = pendingCount
        self.updatedAt = updatedAt
    }

    init?(context: [String: Any]) {
        guard
            context[TransferMetadataKey.type] as? String == Self.contextType,
            let count = context["pendingCount"] as? Int,
            (0...100_000).contains(count),
            let rawTime = context["updatedAt"] as? Double,
            rawTime.isFinite, rawTime > 0
        else { return nil }
        pendingCount = count
        updatedAt = Date(timeIntervalSince1970: rawTime)
    }
}

/// Keep the newest Watch message across iPhone relaunches. Older context
/// deliveries never overwrite a newer known status.
final class WatchQueueStatusCache {
    private let defaults: UserDefaults
    private let countKey = "what.watch.lastPendingCount"
    private let timeKey = "what.watch.lastQueueUpdate"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var latest: WatchQueueSnapshot? {
        guard defaults.object(forKey: timeKey) != nil else { return nil }
        return WatchQueueSnapshot(context: [
            TransferMetadataKey.type: WatchQueueSnapshot.contextType,
            "pendingCount": defaults.integer(forKey: countKey),
            "updatedAt": defaults.double(forKey: timeKey)
        ])
    }

    @discardableResult
    func accept(_ snapshot: WatchQueueSnapshot) -> Bool {
        guard snapshot.updatedAt >= (latest?.updatedAt ?? .distantPast) else {
            return false
        }
        defaults.set(snapshot.pendingCount, forKey: countKey)
        defaults.set(snapshot.updatedAt.timeIntervalSince1970, forKey: timeKey)
        return true
    }
}
