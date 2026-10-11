import Foundation

/// iCloud KVS transport for the optional group organization feature.
/// A versioned last-write-wins record set avoids modifying the published
/// SwiftData schema, and tombstones prevent deleted groups from reappearing.
struct ChickMarkGroupCloudSnapshot: Codable, Equatable {
    struct GroupRecord: Codable, Equatable {
        let id: UUID
        var name: String
        var deleted: Bool
        var revisedAt: Date
        var author: String
    }

    struct MembershipRecord: Codable, Equatable {
        let habitID: UUID
        var groupID: UUID?
        var revisedAt: Date
        var author: String
    }

    var groups: [GroupRecord]
    var memberships: [MembershipRecord]

    static let empty = ChickMarkGroupCloudSnapshot(groups: [], memberships: [])

    /// Deterministic conflict resolution even if two devices have equal clocks.
    /// Clock skew remains a limitation of iCloud KVS last-writer semantics.
    private static func newer<T>(
        _ lhs: T, _ rhs: T, timestamp: (T) -> Date, author: (T) -> String
    ) -> T {
        if timestamp(lhs) != timestamp(rhs) {
            return timestamp(lhs) > timestamp(rhs) ? lhs : rhs
        }
        return author(lhs) >= author(rhs) ? lhs : rhs
    }

    func joined(with remote: Self) -> Self {
        var groupMap = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        for incoming in remote.groups {
            if let prior = groupMap[incoming.id] {
                groupMap[incoming.id] = Self.newer(
                    prior, incoming,
                    timestamp: { $0.revisedAt }, author: { $0.author }
                )
            } else {
                groupMap[incoming.id] = incoming
            }
        }

        var memberMap = Dictionary(
            uniqueKeysWithValues: memberships.map { ($0.habitID, $0) }
        )
        for incoming in remote.memberships {
            if let prior = memberMap[incoming.habitID] {
                memberMap[incoming.habitID] = Self.newer(
                    prior, incoming,
                    timestamp: { $0.revisedAt }, author: { $0.author }
                )
            } else {
                memberMap[incoming.habitID] = incoming
            }
        }

        return Self(
            groups: groupMap.values.sorted {
                $0.id.uuidString < $1.id.uuidString
            },
            memberships: memberMap.values.sorted {
                $0.habitID.uuidString < $1.habitID.uuidString
            }
        )
    }

    func materialize() -> [ChickMarkGroup] {
        let live = groups.filter { !$0.deleted }
        var result = live.map {
            ChickMarkGroup(id: $0.id, name: $0.name, habitIDs: [])
        }.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        for member in memberships {
            guard let groupID = member.groupID,
                  let index = result.firstIndex(where: { $0.id == groupID })
            else { continue }
            result[index].habitIDs.append(member.habitID)
        }
        for index in result.indices {
            result[index].habitIDs.sort { $0.uuidString < $1.uuidString }
        }
        return result
    }

    /// Diff the editable local projection against the last synced snapshot.
    /// Record only changed assignments, not every group at each save.
    func applyingLocalChange(
        from before: [ChickMarkGroup],
        to after: [ChickMarkGroup],
        at time: Date,
        author: String
    ) -> Self {
        let baseline = self
        var changes = Self.empty

        let oldNames = Dictionary(uniqueKeysWithValues: before.map { ($0.id, $0.name) })
        let newNames = Dictionary(uniqueKeysWithValues: after.map { ($0.id, $0.name) })
        for (id, name) in newNames where oldNames[id] != name {
            changes.groups.append(.init(
                id: id, name: name, deleted: false,
                revisedAt: time, author: author
            ))
        }
        for (id, name) in oldNames where newNames[id] == nil {
            changes.groups.append(.init(
                id: id, name: name, deleted: true,
                revisedAt: time, author: author
            ))
        }

        func assignmentMap(_ groups: [ChickMarkGroup]) -> [UUID: UUID] {
            var map: [UUID: UUID] = [:]
            for group in groups {
                for id in group.habitIDs { map[id] = group.id }
            }
            return map
        }

        let beforeAssignments = assignmentMap(before)
        let afterAssignments = assignmentMap(after)
        for habitID in Set(beforeAssignments.keys).union(afterAssignments.keys)
        where beforeAssignments[habitID] != afterAssignments[habitID] {
            changes.memberships.append(.init(
                habitID: habitID, groupID: afterAssignments[habitID],
                revisedAt: time, author: author
            ))
        }
        return baseline.joined(with: changes)
    }
}

@MainActor
final class ChickMarkGroupsCloudSync {
    static let shared = ChickMarkGroupsCloudSync()

    private let cloud = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private let remoteKey = "chickmark.groups.cloud.v1"
    private let localKey = "chickmark.groups.ledger.v1"
    private let authorKey = "chickmark.groups.device-id.v1"
    private var observing = false
    private var enabled = false

    private var author: String {
        if let existing = defaults.string(forKey: authorKey) {
            return existing
        }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: authorKey)
        return generated
    }

    private func localLedger() -> ChickMarkGroupCloudSnapshot {
        guard let data = defaults.data(forKey: localKey),
              let snapshot = try? JSONDecoder().decode(
                ChickMarkGroupCloudSnapshot.self, from: data
              ) else { return .empty }
        return snapshot
    }

    private func remoteLedger() -> ChickMarkGroupCloudSnapshot {
        guard let data = cloud.data(forKey: remoteKey),
              let snapshot = try? JSONDecoder().decode(
                ChickMarkGroupCloudSnapshot.self, from: data
              ) else { return .empty }
        return snapshot
    }

    func start() {
        guard !observing else { return }
        enabled = true
        observing = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(remoteDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )
        reconcile()
        cloud.synchronize()
    }

    /// KVS notifications may arrive on arbitrary queues, so marshal updates
    /// to the main actor before touching UI-observed UserDefaults.
    @objc nonisolated private func remoteDidChange(_ notification: Notification) {
        let reason = (notification.userInfo?[
            NSUbiquitousKeyValueStoreChangeReasonKey
        ] as? Int) ?? 0
        guard reason != NSUbiquitousKeyValueStoreQuotaViolationChange else {
            return
        }
        Task { @MainActor [weak self] in
            self?.reconcile()
        }
    }

    func localDidChange(from before: [ChickMarkGroup], to after: [ChickMarkGroup]) {
        guard enabled, before != after else { return }
        let base = localLedger()
        let next = base.applyingLocalChange(
            from: before, to: after, at: Date(), author: author
        )
        persist(next)
    }

    private func reconcile() {
        let local = localLedger()
        let remote = remoteLedger()
        let onDevice = ChickMarkGroups.load()

        // First launch after upgrading: preserve existing local-only groups.
        let seed: ChickMarkGroupCloudSnapshot
        if local == .empty && !onDevice.isEmpty {
            seed = local.applyingLocalChange(
                from: [], to: onDevice, at: .distantPast, author: author
            )
        } else {
            seed = local
        }
        let merged = seed.joined(with: remote)
        persist(merged)
    }

    private func persist(_ snapshot: ChickMarkGroupCloudSnapshot) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        guard let data = try? encoder.encode(snapshot),
              data.count <= 250_000 else {
            // Local groups remain usable even if iCloud quota would be exceeded.
            return
        }
        defaults.set(data, forKey: localKey)
        let view = snapshot.materialize()
        // Bypass the mutation API to avoid feedback loops.
        if let viewData = try? JSONEncoder().encode(view) {
            defaults.set(viewData, forKey: ChickMarkGroups.storageKey)
        }
        if cloud.data(forKey: remoteKey) != data {
            cloud.set(data, forKey: remoteKey)
        }
    }
}
