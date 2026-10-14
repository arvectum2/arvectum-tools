import Foundation

/// A watch-local HealthKit measurement for display only. Never encode this
/// value into HabitSyncSnapshot, WatchConnectivity, CloudKit or diagnostics.
struct WatchHealthProgress: Equatable {
    let metric: String
    let current: Double
    let target: Double

    var fraction: Double {
        guard current.isFinite, target.isFinite, target > 0 else { return 0 }
        return min(max(current / target, 0), 1)
    }

    var unitKey: String {
        switch metric {
        case "steps": "watch.health.unit.steps"
        case "walkingDistance": "watch.health.unit.kilometers"
        case "workoutMinutes", "runningWorkout": "watch.health.unit.minutes"
        case "sleepHours": "watch.health.unit.hours"
        default: "watch.health.unit.unknown"
        }
    }

    func quantityText(locale: Locale) -> String {
        guard current.isFinite, target.isFinite, target > 0 else { return "—" }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = metric == "steps" ? 0 : 1
        formatter.minimumFractionDigits = 0
        func formatted(_ value: Double) -> String {
            formatter.string(from: NSNumber(value: max(0, value))) ?? "—"
        }
        return "\(formatted(current)) / \(formatted(target))"
    }
}
