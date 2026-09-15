import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Soft-fail WidgetKit timeline reload for Watch face complications after App Group
/// `lastWatchSnapshot` writes (Honest #37).
///
/// Kind must match `ReadinessWatchComplication.kind` in
/// `ReadinessTrackerWatchWidgets/ReadinessWatchComplication.swift`.
enum WatchComplicationTimelineReloader {
    static let kind = "ReadinessWatchComplication"

    /// Reloads timelines for the Watch Widgets kind so complications update without
    /// waiting for the next timeline policy. Inject `reload` in tests; production
    /// default calls `WidgetCenter` when WidgetKit is available (no-op otherwise).
    static func reloadAfterSnapshotWrite(using reload: ((String) -> Void)? = nil) {
        let perform = reload ?? defaultReload
        perform(kind)
    }

    private static func defaultReload(_ kind: String) {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        #else
        _ = kind
        #endif
    }
}
