import Foundation

/// Typed domain representation of the published Habit.weeklyTarget storage.
/// This adapter isolates encoding details without changing the CloudKit schema.
enum HabitGoalMode: Equatable {
    case scheduled
    case weekly(times: Int)
    case afterCompletion(days: Int)
    case multiCheck(times: Int)
    case quantity(count: Int)
    case duration(minutes: Int)

    init(storedValue value: Int) {
        switch value {
        case 1...7:
            self = .weekly(times: value)
        case -365 ... -1:
            self = .afterCompletion(days: -value)
        case 1002...1005:
            self = .multiCheck(times: value - 1000)
        case 3001...3100:
            self = .quantity(count: value - 3000)
        case 5001...5024:
            self = .duration(minutes: (value - 5000) * 5)
        default:
            self = .scheduled
        }
    }

    var storedValue: Int {
        switch self {
        case .scheduled: return 0
        case .weekly(let times): return min(max(times, 1), 7)
        case .afterCompletion(let days): return -min(max(days, 1), 365)
        case .multiCheck(let times): return 1000 + min(max(times, 2), 5)
        case .quantity(let count): return 3000 + min(max(count, 1), 100)
        case .duration(let minutes):
            let steps = min(max((minutes + 4) / 5, 1), 24)
            return 5000 + steps
        }
    }

    var target: Int {
        switch self {
        case .multiCheck(let times): return times
        case .quantity(let count): return count
        case .duration(let minutes): return minutes / 5
        default: return 1
        }
    }
}
