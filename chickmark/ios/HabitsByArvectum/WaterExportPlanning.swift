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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func rule(for habitID: UUID) -> WaterExportRule? {
        load([String: WaterExportRule].self, key: rulesKey)?[habitID.uuidString]
    }

    func setRule(_ rule: WaterExportRule?, for habitID: UUID) {
        guard rule == nil || rule?.isValid == true else { return }
        var all = load([String: WaterExportRule].self, key: rulesKey) ?? [:]
        all[habitID.uuidString] = rule
        save(all, key: rulesKey)
    }

    func receipt(habitID: UUID, dayKey: String) -> WaterExportReceipt? {
        load([String: WaterExportReceipt].self, key: receiptsKey)?[
            WaterExportPlanning.syncIdentifier(habitID: habitID, dayKey: dayKey)
        ]
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
