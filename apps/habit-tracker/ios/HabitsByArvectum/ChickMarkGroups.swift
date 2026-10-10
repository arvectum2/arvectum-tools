import Foundation

/// Optional organization backed by local preferences, iCloud KVS and JSON
/// backup. The published Habit/CloudKit SwiftData model is unchanged.
struct ChickMarkGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var habitIDs: [UUID]
}

@MainActor
enum ChickMarkGroups {
    static let storageKey = "chickmark.groups.v1"

    static func decode(_ data: Data) -> [ChickMarkGroup] {
        (try? JSONDecoder().decode([ChickMarkGroup].self, from: data)) ?? []
    }

    static func load(defaults: UserDefaults = .standard) -> [ChickMarkGroup] {
        decode(defaults.data(forKey: storageKey) ?? Data())
    }

    static func save(
        _ groups: [ChickMarkGroup],
        defaults: UserDefaults = .standard
    ) {
        guard let data = try? JSONEncoder().encode(groups) else { return }
        let prior = load(defaults: defaults)
        defaults.set(data, forKey: storageKey)
        if defaults === UserDefaults.standard {
            ChickMarkGroupsCloudSync.shared.localDidChange(
                from: prior, to: groups
            )
        }
    }

    static func create(
        name: String, defaults: UserDefaults = .standard
    ) -> ChickMarkGroup? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var groups = load(defaults: defaults)
        guard !groups.contains(where: {
            $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }) else { return nil }
        let group = ChickMarkGroup(id: UUID(), name: trimmed, habitIDs: [])
        groups.append(group)
        save(groups, defaults: defaults)
        return group
    }

    static func assign(
        habitID: UUID, to groupID: UUID?,
        defaults: UserDefaults = .standard
    ) {
        var groups = load(defaults: defaults)
        for index in groups.indices {
            groups[index].habitIDs.removeAll { $0 == habitID }
            if groups[index].id == groupID {
                groups[index].habitIDs.append(habitID)
            }
        }
        save(groups, defaults: defaults)
    }

    static func groupID(
        for habitID: UUID, defaults: UserDefaults = .standard
    ) -> UUID? {
        load(defaults: defaults).first {
            $0.habitIDs.contains(habitID)
        }?.id
    }

    static func delete(id: UUID, defaults: UserDefaults = .standard) {
        save(load(defaults: defaults).filter { $0.id != id }, defaults: defaults)
    }

    static func merge(
        _ incoming: [ChickMarkGroup],
        defaults: UserDefaults = .standard
    ) {
        var groups = load(defaults: defaults)
        let existingIDs = Set(groups.map(\.id))
        groups += incoming.filter { !existingIDs.contains($0.id) }
        save(groups, defaults: defaults)
    }
}
