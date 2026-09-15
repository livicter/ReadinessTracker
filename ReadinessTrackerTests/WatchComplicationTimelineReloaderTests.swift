import XCTest
@testable import Readiness

/// Honest #37: seam proves Watch Widgets kind is reloaded after snapshot write hooks.
final class WatchComplicationTimelineReloaderTests: XCTestCase {
    func testKindMatchesWatchWidgetsStaticConfiguration() {
        XCTAssertEqual(
            WatchComplicationTimelineReloader.kind,
            "ReadinessWatchComplication",
            "Must match ReadinessWatchComplication.kind in ReadinessTrackerWatchWidgets"
        )
    }

    func testReloadAfterSnapshotWriteInvokesInjectedHookWithWatchKind() {
        var seen: [String] = []
        WatchComplicationTimelineReloader.reloadAfterSnapshotWrite { seen.append($0) }
        XCTAssertEqual(seen, ["ReadinessWatchComplication"])
    }

    func testDefaultReloadSoftFailsWithoutCrashing() {
        // WidgetCenter.shared.reloadTimelines is safe for unknown/absent kinds on iOS;
        // proves the production path does not throw when WidgetKit is linked.
        WatchComplicationTimelineReloader.reloadAfterSnapshotWrite()
    }
}
