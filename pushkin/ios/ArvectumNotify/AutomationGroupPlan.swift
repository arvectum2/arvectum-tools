import Foundation

/// A voluntary planning aid, NOT an iOS Shortcuts service limit.
/// A physical iOS 27 experiment preserved 1000 SelectedApps in one
/// Notification automation. Only the Shortcuts app can enable automations.
enum AutomationGroupPlan {
    static let suggestedGroupSize = 25

    static func toggle(_ bundleID: String, in selectedIDs: [String]) -> [String] {
        guard !bundleID.isEmpty else { return unique(selectedIDs) }
        var result = unique(selectedIDs)
        if let index = result.firstIndex(of: bundleID) {
            result.remove(at: index)
        } else {
            result.append(bundleID)
        }
        return result
    }

    static func unique(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    static func groups<T>(
        _ entries: [T],
        size: Int = suggestedGroupSize
    ) -> [[T]] {
        guard size > 0, !entries.isEmpty else { return [] }
        return stride(from: 0, to: entries.count, by: size).map {
            Array(entries[$0..<min($0 + size, entries.count)])
        }
    }

    static func encode(_ ids: [String]) -> String {
        guard let data = try? JSONEncoder().encode(unique(ids)),
              let value = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return value
    }

    static func decode(_ value: String) -> [String] {
        guard let data = value.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return unique(ids)
    }
}
