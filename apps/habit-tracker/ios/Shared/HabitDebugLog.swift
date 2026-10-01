#if DEBUG
import Foundation

enum HabitDebugLog {
    static func emit(_ message: String) {
        NSLog("%@", message)
    }
}
#endif
