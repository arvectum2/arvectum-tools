import Foundation

enum HabitDeepLink {
    static let scheme = "habits-arvectum"

    enum Destination: Equatable {
        case today
        case habit(UUID)
    }

    static let todayURL = URL(string: "\(scheme)://today")!

    static func habitURL(_ habitID: UUID) -> URL {
        URL(string: "\(scheme)://habit/\(habitID.uuidString)")!
    }

    static func destination(from url: URL) -> Destination? {
        guard url.scheme?.lowercased() == scheme else { return nil }

        switch url.host?.lowercased() {
        case "today":
            return .today
        case "habit":
            let rawID = url.pathComponents
                .filter { $0 != "/" }
                .first
            guard let rawID, let id = UUID(uuidString: rawID) else {
                return nil
            }
            return .habit(id)
        default:
            return nil
        }
    }
}
