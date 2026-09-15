import Foundation

/// Shared post-write hook so Home widgets stay fresh after any path that
/// changes readiness scores (Honest #43).
///
/// Production: `WidgetDataExporter.export` (App Group + WidgetCenter reload
/// inside exporter) then `WatchConnectivityManager.pushSnapshot`.
///
/// Call sites:
/// - `DataStore.persist` — HealthKit / Fitbit `save` paths
/// - `MetadataStore.persist` — Morning / Evening Check-in (and Watch check-in
///   that lands in MetadataStore)
///
/// Inject `testPerform` in XCTest; do not add a second WidgetCenter.reload at
/// call sites — exporter already reloads `ReadinessTrackerWidget`.
enum WidgetExportAfterWrite {
    /// Test-only override; production leaves `nil`.
    @MainActor
    static var testPerform: (@MainActor (DataStore) -> Void)?

    @MainActor
    static func run(dataStore: DataStore? = nil) {
        let store = dataStore ?? DataStore.shared
        if let testPerform {
            testPerform(store)
            return
        }
        WidgetDataExporter.export(from: store)
        WatchConnectivityManager.shared.pushSnapshot()
    }
}
