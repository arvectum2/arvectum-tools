import Foundation

/// Per-habit, explicit local opt-in. A quantity check-in is not a volume until
/// the user enters its size in millilitres. This is NOT an inferred value
/// based on the habit title or symbol.
struct WaterExportRule: Codable, Equatable {
    let millilitresPerUnit: Int
    let enabledAt: Date

    var isValid: Bool {
        (10...1_000).contains(millilitresPerUnit)
    }
}

/// Record of the last successfully exported aggregate for a single habit/day.
/// Do not persist an attempted write as successful. Kept outside SwiftData and
/// CloudKit, never sent to Watch, ads or analytics.
struct WaterExportReceipt: Codable, Equatable {
    let syncIdentifier: String
    let quantity: Int
    let millilitres: Int
    let syncVersion: Int
}

enum WaterExportAction: Equatable {
    case none
    case upsert(identifier: String, millilitres: Int, syncVersion: Int)
    case delete(identifier: String)
}

/// Pure reconciliation policy; the HealthKit writer must apply an operation
/// transactionally and only then persist its receipt.
enum WaterExportPlanning {
    static func syncIdentifier(habitID: UUID, dayKey: String) -> String {
        "ru.arvectum.chickmark.water.v1.\(habitID.uuidString).\(dayKey)"
    }

    static func action(
        habitID: UUID,
        dayKey: String,
        goal: HabitGoalMode,
        currentCount: Int,
        rule: WaterExportRule?,
        receipt: WaterExportReceipt?,
        calendar: Calendar = .autoupdatingCurrent
    ) -> WaterExportAction {
        let identifier = syncIdentifier(habitID: habitID, dayKey: dayKey)
        // A previously committed own sample remains eligible for cleanup if
        // the user disables the rule or changes the habit away from quantity.
        let activeRule: WaterExportRule?
        if let rule, rule.isValid, isQuantity(goal),
           dayIsOnOrAfterOptIn(dayKey, enabledAt: rule.enabledAt, calendar: calendar) {
            activeRule = rule
        } else {
            activeRule = nil
        }
        let count = activeRule == nil ? 0 : min(max(currentCount, 0), goal.target)
        let volume = count * (activeRule?.millilitresPerUnit ?? 0)

        // Never delete a sample that is not known to belong to this specific
        // habit/day; never overwrite another app's dietaryWater measurement.
        if volume == 0 {
            return receipt?.syncIdentifier == identifier ? .delete(identifier: identifier) : .none
        }
        if receipt?.syncIdentifier == identifier,
           receipt?.quantity == count, receipt?.millilitres == volume {
            return .none
        }
        let nextVersion = (receipt?.syncIdentifier == identifier ? receipt?.syncVersion ?? 0 : 0) + 1
        return .upsert(identifier: identifier, millilitres: volume, syncVersion: nextVersion)
    }

    private static func isQuantity(_ goal: HabitGoalMode) -> Bool {
        if case .quantity = goal { return true }
        return false
    }

    private static func dayIsOnOrAfterOptIn(
        _ dayKey: String, enabledAt: Date, calendar: Calendar
    ) -> Bool {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              let date = calendar.date(from: DateComponents(
                calendar: calendar, timeZone: calendar.timeZone,
                year: parts[0], month: parts[1], day: parts[2], hour: 12
              )), HabitDayKey.make(for: date, calendar: calendar) == dayKey
        else { return false }
        return calendar.startOfDay(for: date) >= calendar.startOfDay(for: enabledAt)
    }
}

/// Explicit preferences and applied receipts are LOCAL ONLY. Nothing is
/// written to Apple Health simply by instantiating this store.
final class WaterExportLocalStore {
    private let defaults: UserDefaults
    private let rulesKey = "chickmark.water.rules.v1"
    private let receiptsKey = "chickmark.water.receipts.v1"
    private let pendingKey = "chickmark.water.pendingWriteVersions.v1"
    private let versionsKey = "chickmark.water.highestSyncVersions.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Fail closed when a persisted ledger cannot be decoded. A damaged
    /// consent map must NOT be interpreted as no consent and used to erase
    /// previously exported HealthKit water samples. This protects all three
    /// separately persisted maps: opt-ins, applied receipts and write intents.
    var canSafelyReconcile: Bool {
        readable([String: WaterExportRule].self, key: rulesKey)
            && readable([String: WaterExportReceipt].self, key: receiptsKey)
            && readable([String: Int].self, key: pendingKey)
            && readable([String: Int].self, key: versionsKey)
    }

    private func readable<T: Decodable>(_ type: T.Type, key: String) -> Bool {
        guard let data = defaults.data(forKey: key) else {
            // Never opted in or no previous export is a valid empty ledger.
            return true
        }
        return (try? JSONDecoder().decode(type, from: data)) != nil
    }

    func rule(for habitID: UUID) -> WaterExportRule? {
        load([String: WaterExportRule].self, key: rulesKey)?[habitID.uuidString]
    }

    var allRules: [(habitID: UUID, rule: WaterExportRule)] {
        (load([String: WaterExportRule].self, key: rulesKey) ?? [:])
            .compactMap { key, rule in
                UUID(uuidString: key).map { (habitID: $0, rule: rule) }
            }
    }

    func receipts(for habitID: UUID) -> [(dayKey: String, receipt: WaterExportReceipt)] {
        let prefix = "ru.arvectum.chickmark.water.v1.\(habitID.uuidString)."
        return (load([String: WaterExportReceipt].self, key: receiptsKey) ?? [:])
            .compactMap { key, receipt in
                guard key.hasPrefix(prefix), receipt.syncIdentifier == key else { return nil }
                return (String(key.dropFirst(prefix.count)), receipt)
            }
    }

    @discardableResult
    func setRule(_ rule: WaterExportRule?, for habitID: UUID) -> Bool {
        // Never silently overwrite a damaged consent/receipt/intent ledger
        // with an empty dictionary when the user taps Save or Cancel.
        guard canSafelyReconcile,
              rule == nil || rule?.isValid == true else { return false }
        var all = load([String: WaterExportRule].self, key: rulesKey) ?? [:]
        all[habitID.uuidString] = rule
        save(all, key: rulesKey)
        return true
    }

    func receipt(habitID: UUID, dayKey: String) -> WaterExportReceipt? {
        load([String: WaterExportReceipt].self, key: receiptsKey)?[
            WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        ]
    }

    /// Persist the intended metadata version BEFORE the HealthKit call.
    /// An interrupted successful write is replayed with a higher version,
    /// which replaces (rather than doubles) the previously saved sample.
    func pendingVersion(habitID: UUID, dayKey: String) -> Int? {
        let key = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        return load([String: Int].self, key: pendingKey)?[key]
    }

    func setPendingVersion(_ version: Int?, habitID: UUID, dayKey: String) {
        let key = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        var all = load([String: Int].self, key: pendingKey) ?? [:]
        all[key] = version
        save(all, key: pendingKey)
    }

    /// Monotonic sync-version watermark survives an undo/deletion. Without
    /// it, a re-created record for the same habit and day would restart at
    /// version 1 even if HealthKit had already seen version 4 for that ID.
    func highestVersion(habitID: UUID, dayKey: String) -> Int {
        let key = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        return max(0, load([String: Int].self, key: versionsKey)?[key] ?? 0)
    }

    @discardableResult
    func noteVersion(_ version: Int, habitID: UUID, dayKey: String) -> Bool {
        guard canSafelyReconcile, version > 0 else { return false }
        let key = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        var all = load([String: Int].self, key: versionsKey) ?? [:]
        all[key] = max(all[key] ?? 0, version)
        save(all, key: versionsKey)
        return true
    }

    func pendingDays(for habitID: UUID) -> [String] {
        let prefix = "ru.arvectum.chickmark.water.v1.\(habitID.uuidString)."
        return (load([String: Int].self, key: pendingKey) ?? [:]).keys
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
    }

    var allKnownHabitIDs: Set<UUID> {
        let prefix = "ru.arvectum.chickmark.water.v1."
        let suffixes = Array((load([String: WaterExportReceipt].self, key: receiptsKey) ?? [:]).keys)
            + Array((load([String: Int].self, key: pendingKey) ?? [:]).keys)
        return Set(suffixes.compactMap { key in
            guard key.hasPrefix(prefix) else { return nil }
            return UUID(uuidString: String(key.dropFirst(prefix.count).prefix(36)))
        })
    }

    /// Only the successful HealthKit writer may commit or clear this receipt.
    func setReceipt(_ receipt: WaterExportReceipt?, habitID: UUID, dayKey: String) {
        let key = WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        guard receipt == nil || receipt?.syncIdentifier == key else { return }
        var all = load([String: WaterExportReceipt].self, key: receiptsKey) ?? [:]
        all[key] = receipt
        save(all, key: receiptsKey)
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }
}
