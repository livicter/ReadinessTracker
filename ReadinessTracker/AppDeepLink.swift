import Foundation

/// App URL destinations under the existing `readinesstracker://` scheme
/// (Fitbit OAuth already uses `readinesstracker://oauth`).
enum AppDeepLink: Equatable {
    case checkIn(CheckInTime)
    case trends
    case fitbitOAuth

    static let scheme = "readinesstracker"
    static let checkInHost = "checkin"
    static let trendsHost = "trends"

    /// Opens Check-in tab on Morning (widget / Fitness-style action).
    static var checkInMorningURL: URL {
        URL(string: "\(scheme)://\(checkInHost)/morning")!
    }

    /// Opens Check-in tab on Evening (widget secondary / Fitness-style action).
    static var checkInEveningURL: URL {
        URL(string: "\(scheme)://\(checkInHost)/evening")!
    }

    static var checkInURL: URL { checkInMorningURL }

    /// Opens History tab (Browse Trends surface).
    static var trendsURL: URL {
        URL(string: "\(scheme)://\(trendsHost)")!
    }

    static let openCheckInNotification = Notification.Name("ReadinessTracker.openCheckIn")
    static let openTrendsNotification = Notification.Name("ReadinessTracker.openTrends")

    static func parse(_ url: URL) -> AppDeepLink? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        let host = (url.host ?? "").lowercased()

        if host == "oauth" {
            return .fitbitOAuth
        }

        if host == checkInHost {
            return .checkIn(checkInTime(from: url))
        }

        if host == trendsHost {
            return .trends
        }

        // Path-style fallback: readinesstracker:///checkin[/morning|evening]
        // or readinesstracker:///trends
        let parts = url.pathComponents
            .map { $0.lowercased() }
            .filter { $0 != "/" && !$0.isEmpty }
        if parts.first == checkInHost {
            return .checkIn(parts.count > 1 ? time(fromToken: parts[1]) : .morning)
        }
        if parts.first == trendsHost {
            return .trends
        }

        return nil
    }

    private static func checkInTime(from url: URL) -> CheckInTime {
        let path = url.path.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !path.isEmpty {
            return time(fromToken: path)
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let raw = items.first(where: { $0.name.lowercased() == "time" })?.value {
            return time(fromToken: raw)
        }
        return .morning
    }

    /// URL tokens are lowercase (`morning` / `evening`); `CheckInTime.rawValue` is title case.
    private static func time(fromToken raw: String) -> CheckInTime {
        switch raw.lowercased() {
        case "evening", CheckInTime.evening.rawValue.lowercased():
            return .evening
        default:
            return .morning
        }
    }

    static func postOpenCheckIn(_ time: CheckInTime) {
        NotificationCenter.default.post(
            name: openCheckInNotification,
            object: nil,
            userInfo: ["time": time.rawValue]
        )
    }

    static func postOpenTrends() {
        NotificationCenter.default.post(name: openTrendsNotification, object: nil)
    }
}
