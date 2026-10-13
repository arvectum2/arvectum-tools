import Foundation

/// In-memory retry gate for WatchConnectivity background transfers.
///
/// Outstanding WCSession transfers are the source of truth while queued.
/// After delivery, allow a re-send if a durable iPhone ACK never arrived.
/// Stable UUIDs make repeated delivery safe on the receiving side.
struct WatchTransferRetryPolicy {
    static let acknowledgementGracePeriod: TimeInterval = 90

    private var nextEligibleAt: [UUID: Date] = [:]

    func shouldSchedule(_ id: UUID, isOutstanding: Bool, at now: Date) -> Bool {
        guard !isOutstanding else { return false }
        return (nextEligibleAt[id] ?? .distantPast) <= now
    }

    mutating func didSchedule(_ id: UUID, at now: Date) {
        nextEligibleAt[id] = now.addingTimeInterval(Self.acknowledgementGracePeriod)
    }

    mutating func didComplete(_ id: UUID, at now: Date) {
        // Do not immediately re-queue a successful transfer: the ACK may still be in flight.
        nextEligibleAt[id] = now.addingTimeInterval(Self.acknowledgementGracePeriod)
    }

    mutating func didFail(_ id: UUID) {
        // Retry after the caller's short error backoff.
        nextEligibleAt.removeValue(forKey: id)
    }

    mutating func didAcknowledge(_ id: UUID) {
        nextEligibleAt.removeValue(forKey: id)
    }
}
