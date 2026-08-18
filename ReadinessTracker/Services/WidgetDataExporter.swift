import Foundation
import WidgetKit

/// Snapshots today's readiness data into the shared App Group container
/// so the home screen widget (ReadinessTrackerWidget) can render it.
///
/// Call `WidgetDataExporter.export()` after any data refresh (HealthKit/Fitbit
/// sync, manual check-in) to keep the widget up to date.
enum WidgetDataExporter {
    static let appGroupID = "group.com.readinesstracker"

    /// Computes scores from the latest stored day and writes them to the
    /// App Group UserDefaults, then asks WidgetKit to reload timelines.
    @MainActor
    static func export(from store: DataStore? = nil) {
        let store = store ?? DataStore.shared
        guard let latest = store.history.first else { return }
        let history30 = store.dataForSource(latest.source, days: 30)
        let breakdown = ReadinessCalculator.calculateBreakdown(from: latest, history: history30)
        let metadata = MetadataStore.shared.metadataFor(date: Date(), timeOfDay: .morning)
        let dualScores = ReadinessCalculator.calculateDualScores(from: latest, history: history30, metadata: metadata)

        export(
            readinessScore: dualScores.general,
            gymScore: dualScores.gym,
            workScore: dualScores.cognitive,
            sleepScore: breakdown.sleepScore,
            hrv: latest.hrv,
            rhr: latest.restingHeartRate,
            sleepHours: latest.sleepHours
        )
    }

    /// Writes a pre-computed snapshot to the App Group UserDefaults using the
    /// keys the widget's timeline provider reads.
    static func export(readinessScore: Int, gymScore: Int, workScore: Int,
                       sleepScore: Int, hrv: Double, rhr: Double, sleepHours: Double) {
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        sharedDefaults?.set(readinessScore, forKey: "readinessScore")
        sharedDefaults?.set(gymScore, forKey: "gymScore")
        sharedDefaults?.set(workScore, forKey: "workScore")
        sharedDefaults?.set(sleepScore, forKey: "sleepScore")
        sharedDefaults?.set(hrv, forKey: "hrv")
        sharedDefaults?.set(rhr, forKey: "rhr")
        sharedDefaults?.set(sleepHours, forKey: "sleepHours")
        sharedDefaults?.set(Date(), forKey: "lastUpdate")

        WidgetCenter.shared.reloadTimelines(ofKind: "ReadinessTrackerWidget")
    }
}
