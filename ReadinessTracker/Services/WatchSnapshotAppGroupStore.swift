import Foundation

/// Shared App Group writer for the Watch complication / Watch App snapshot dictionary.
///
/// Key and suite match `WatchSessionManager` (Watch App) and `WatchComplicationStore`
/// (Watch Widgets). iOS writes here when a snapshot is pushed so the suite key is
/// populated on the phone side; the Watch App still mirrors on receive for the
/// watch-side container. Portal App Group enable remains manual (`docs/DEVICE_SETUP.md`).
enum WatchSnapshotAppGroupStore {
    static let appGroupID = "group.com.readinesstracker"
    static let snapshotKey = "lastWatchSnapshot"

    /// Persists a WatchConnectivity-shaped snapshot dictionary to the App Group suite.
    static func write(_ dictionary: [String: Any], defaults: UserDefaults? = nil) {
        guard !dictionary.isEmpty else { return }
        let suite = defaults ?? UserDefaults(suiteName: appGroupID)
        suite?.set(dictionary, forKey: snapshotKey)
    }

    /// Reads the last written snapshot dictionary from the App Group suite (or injected defaults).
    static func read(defaults: UserDefaults? = nil) -> [String: Any]? {
        let suite = defaults ?? UserDefaults(suiteName: appGroupID)
        return suite?.dictionary(forKey: snapshotKey)
    }
}
