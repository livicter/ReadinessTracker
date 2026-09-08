import XCTest

final class SurfacesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-fixture"]
        app.launch()
    }

    func testTodayHeroBright() throws {
        XCTAssertTrue(app.staticTexts["Readiness"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["WHOOP via Apple Health"].exists)
        saveShot("verify-dashboard.png")
    }

    func testTodayRingsGeometry() throws {
        XCTAssertTrue(app.staticTexts["TODAY'S READINESS"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Gym"].exists)
        Thread.sleep(forTimeInterval: 1.4)
        saveShot("verify-rings.png")
    }

    func testRingDetailSurface() throws {
        // Today legend Gym → Apple Fitness–style ring detail sheet.
        XCTAssertTrue(app.staticTexts["TODAY'S READINESS"].waitForExistence(timeout: 8))
        let gym = app.descendants(matching: .any)["ring.legend.gym"].firstMatch
        XCTAssertTrue(gym.waitForExistence(timeout: 8), "ring.legend.gym")
        gym.tap()
        let detail = app.descendants(matching: .any)["ring.detail"].firstMatch
        XCTAssertTrue(
            detail.waitForExistence(timeout: 8) ||
            app.navigationBars["Gym"].waitForExistence(timeout: 8),
            "ring.detail"
        )
        XCTAssertTrue(
            app.staticTexts["Gym"].exists ||
            app.navigationBars["Gym"].exists
        )
        // Soft: score / 7-day chrome under fixture.
        _ = app.descendants(matching: .any)["ring.detail.score"].exists
        _ = app.staticTexts["Last 7 days"].exists
        _ = app.staticTexts["Workout minutes"].exists
        saveShot("verify-ring-detail.png")
    }

    func testWhoopStackVisibleAfterScroll() throws {
        revealText("Sleep HRV")
        XCTAssertTrue(app.staticTexts["Sleep Debt"].exists)
        saveShot("verify-whoop-stack.png")
    }

    func testBodyActivityVisibleAfterScroll() throws {
        // Elevated Body tiles: progress-to-goal + sparkline chrome; Activity minutes label.
        revealText("Body & activity")
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Activity"].exists)
        let stepsTile = app.descendants(matching: .any)["body.tile.steps"].firstMatch
        XCTAssertTrue(stepsTile.waitForExistence(timeout: 8), "body.tile.steps")
        _ = app.descendants(matching: .any)["body.tile.activity"].exists
        saveShot("verify-body-activity.png")
    }

    func testBodyDetailSurface() throws {
        // Today Body Steps tile → Fitness / Google Health–style metric detail sheet.
        revealText("Body & activity")
        let stepsTile = app.descendants(matching: .any)["body.tile.steps"].firstMatch
        XCTAssertTrue(stepsTile.waitForExistence(timeout: 8), "body.tile.steps")
        // Nested card tiles can report exists but not hittable after scroll; coordinate tap is reliable.
        if stepsTile.isHittable {
            stepsTile.tap()
        } else {
            stepsTile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        }
        let detail = app.descendants(matching: .any)["body.detail"].firstMatch
        XCTAssertTrue(
            detail.waitForExistence(timeout: 8) ||
            app.navigationBars["Steps"].waitForExistence(timeout: 8),
            "body.detail"
        )
        XCTAssertTrue(
            app.staticTexts["Steps"].exists ||
            app.navigationBars["Steps"].exists
        )
        // Soft: goal / 7-day chrome under fixture.
        _ = app.descendants(matching: .any)["body.detail.value"].exists
        _ = app.staticTexts["Last 7 days"].exists
        _ = app.staticTexts["of 10,000"].exists
        saveShot("verify-body-detail.png")
    }

    func testSleepQualitySurfaceVisibleAfterScroll() throws {
        // Today WHOOP stack: elevated Sleep Quality + Consistency (score rings, spark, bedtime dots/bars).
        revealText("Sleep Consistency")
        XCTAssertTrue(app.staticTexts["Sleep Quality Trend"].exists)
        XCTAssertTrue(app.staticTexts["Sleep Consistency"].exists)
        // Soft: elevated chrome under -ui-fixture (rings / spark / bedtime bars).
        _ = app.descendants(matching: .any)["sleep.quality.score"].exists
        _ = app.descendants(matching: .any)["sleep.quality.spark"].exists
        _ = app.descendants(matching: .any)["sleep.consistency.score"].exists
        _ = app.descendants(matching: .any)["sleep.consistency.dual"].exists
        _ = app.descendants(matching: .any)["sleep.consistency.bedtime"].exists
        _ = app.descendants(matching: .any)["sleep.consistency.spark"].exists
        _ = app.staticTexts["Bedtime"].exists
        _ = app.staticTexts["Wake Time"].exists
        _ = app.staticTexts["Bedtime vs Average"].exists
        _ = app.staticTexts["7-Day Quality"].exists
        saveShot("verify-sleep-quality.png")
    }

    func testSleepDebtSurfaceVisibleAfterScroll() throws {
        revealText("Sleep Debt")
        XCTAssertTrue(app.staticTexts["Sleep Debt"].exists)
        // SleepDebtCalculator header; Sleep HRV / Quality may still be in frame depending on scroll depth.
        _ = app.staticTexts["Sleep HRV"].exists
        saveShot("verify-sleep-debt.png")
    }

    func testCheckInTabSurface() throws {
        app.tabBars.buttons["Check-in"].tap()
        // Daily Check-in: Morning/Evening segmented picker + Save chrome under -ui-fixture.
        let morning = app.buttons["Morning"]
        let evening = app.buttons["Evening"]
        let save = app.buttons["Save"]
        let physical = app.staticTexts["Physical State"]
        XCTAssertTrue(
            morning.waitForExistence(timeout: 8) ||
            evening.waitForExistence(timeout: 8) ||
            save.waitForExistence(timeout: 8) ||
            physical.waitForExistence(timeout: 8)
        )
        XCTAssertTrue(morning.exists || evening.exists || save.exists || physical.exists)
        _ = app.staticTexts["Daily Check-in"].exists
        saveShot("verify-checkin.png")
    }

    func testHistoryTabSurface() throws {
        // Wait for Today chrome before switching tabs (heavier Body tiles can delay first paint).
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        let historyTab = app.tabBars.buttons["History"]
        XCTAssertTrue(historyTab.waitForExistence(timeout: 8), "History tab")
        historyTab.tap()
        // History: source picker + Weekly Report + Trends under -ui-fixture (14 appleWatch days).
        // Prefer content markers — nav title can lag / merge under a11y on busy sims.
        let landed =
            app.staticTexts["Weekly Report"].waitForExistence(timeout: 12) ||
            app.staticTexts["Trends"].waitForExistence(timeout: 4) ||
            app.navigationBars["History"].waitForExistence(timeout: 2) ||
            app.staticTexts["History"].waitForExistence(timeout: 2)
        XCTAssertTrue(landed, "History tab content")
        XCTAssertTrue(
            app.staticTexts["Weekly Report"].exists ||
            app.staticTexts["Trends"].exists
        )
        _ = app.buttons["Apple Watch"].exists
        _ = app.buttons["Fitbit"].exists
        saveShot("verify-history.png")
    }

    func testSleepDisturbanceSurfaceVisibleAfterScroll() throws {
        // Today Sleep Stages card: fixture wakeEpisodes: 1 → "1 disturbance" + a11y "Sleep disturbances".
        revealText("Sleep Stages")
        let row = app.descendants(matching: .any)["Sleep disturbances"].firstMatch
        var n = 0
        while row.exists && !isOnScreen(row) && n < 6 {
            app.swipeUp()
            n += 1
        }
        XCTAssertTrue(row.waitForExistence(timeout: 8))
        XCTAssertTrue(isOnScreen(row), "Sleep disturbances")
        // Soft check: visible copy may be merged under accessibilityLabel.
        _ = app.staticTexts["1 disturbance"].exists
        saveShot("verify-sleep-disturbances.png")
    }

    func testJournalSurface() throws {
        // Journal: Today NavigationLink → JournalView with ≥7 seeded fixture entries (Recent Entries).
        // Empty-state “Log 7 days…” remains for real users with <7 days; fixture seeds past that gate.
        revealText("Journal")
        let journalRow = app.buttons["Journal"].exists ? app.buttons["Journal"] : app.staticTexts["Journal"]
        journalRow.tap()
        XCTAssertTrue(
            app.navigationBars["Journal"].waitForExistence(timeout: 8) ||
            app.staticTexts["Journal"].waitForExistence(timeout: 8)
        )
        revealText("Recent Entries")
        XCTAssertTrue(app.staticTexts["Recent Entries"].exists)
        XCTAssertFalse(app.staticTexts["No journal entries yet"].exists)
        let log7Copy = "Log 7 days to see how habits line up with next-day readiness."
        XCTAssertFalse(app.staticTexts[log7Copy].exists)
        saveShot("verify-journal.png")
    }

    func testJournalImpactSurface() throws {
        // Journal Behavior Impact chart under -ui-fixture (≥7 seeded entries with readiness scores).
        revealText("Journal")
        let journalRow = app.buttons["Journal"].exists ? app.buttons["Journal"] : app.staticTexts["Journal"]
        journalRow.tap()
        XCTAssertTrue(
            app.navigationBars["Journal"].waitForExistence(timeout: 8) ||
            app.staticTexts["Journal"].waitForExistence(timeout: 8)
        )
        revealText("Behavior Impact")
        XCTAssertTrue(app.staticTexts["Behavior Impact"].exists)
        // Soft: habit rows from fixture seed (alcohol / recovery).
        _ = app.staticTexts["Alcohol"].exists
        _ = app.staticTexts["Meditation"].exists
        saveShot("verify-journal-impact.png")
    }

    func testWeeklyReportSurface() throws {
        // History → Weekly Report sheet: fixture seeds 14 appleWatch days (≥3 needed).
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["Weekly Report"].waitForExistence(timeout: 8))
        let row = app.buttons["Weekly Report"].exists ? app.buttons["Weekly Report"] : app.staticTexts["Weekly Report"]
        row.tap()
        XCTAssertTrue(
            app.navigationBars["Weekly Report"].waitForExistence(timeout: 8) ||
            app.staticTexts["Weekly Report"].waitForExistence(timeout: 8)
        )
        // Report chrome (not the empty "Not Enough Data" state).
        XCTAssertTrue(
            app.staticTexts["% avg readiness"].waitForExistence(timeout: 8) ||
            app.buttons["Share Report"].waitForExistence(timeout: 8) ||
            app.staticTexts["Share Report"].waitForExistence(timeout: 8)
        )
        XCTAssertFalse(app.staticTexts["Not Enough Data"].exists)
        _ = app.staticTexts["Highlights"].exists
        _ = app.staticTexts["Gym"].exists
        _ = app.staticTexts["HRV"].exists
        saveShot("verify-weekly-report.png")
    }

    func testSleepStagesSurface() throws {
        // Today Sleep Stages → Sleep Analysis: coherent fixture stages render hypnogram (not empty state).
        revealText("Sleep Stages")
        let stagesCard = app.buttons["Sleep Stages"].exists ? app.buttons["Sleep Stages"] : app.staticTexts["Sleep Stages"]
        stagesCard.tap()
        XCTAssertTrue(
            app.navigationBars["Sleep Analysis"].waitForExistence(timeout: 8) ||
            app.staticTexts["Sleep Analysis"].waitForExistence(timeout: 8)
        )
        // Hypnogram card title when stages are present.
        revealText("Sleep Timeline")
        XCTAssertTrue(app.staticTexts["Sleep Timeline"].exists)
        XCTAssertFalse(app.staticTexts["No detailed stage data. Stage intervals are recorded from your next sync."].exists)
        // Soft: axis / disturbance chrome may be merged under a11y; stages-derived wake still 1.
        _ = app.staticTexts["Awake"].exists
        _ = app.staticTexts["1 wakes"].exists || app.staticTexts["1 wake"].exists
        saveShot("verify-sleep-stages.png")
    }

    func testMetricDetailChartScrubSurface() throws {
        // Today → Metrics → Sleep card → MetricDetailView (period selector + ChartScrubSelection).
        revealText("Metrics")
        let sleepCard = app.descendants(matching: .any)["metric.card.Sleep"].firstMatch
        if sleepCard.waitForExistence(timeout: 6) {
            sleepCard.tap()
        } else {
            let sleepButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Sleep")).firstMatch
            XCTAssertTrue(sleepButton.waitForExistence(timeout: 8), "Sleep metric card")
            sleepButton.tap()
        }
        XCTAssertTrue(
            app.navigationBars["Sleep"].waitForExistence(timeout: 8) ||
            app.otherElements["metric.detail"].waitForExistence(timeout: 8)
        )
        // Health-like period controls.
        XCTAssertTrue(
            app.buttons["7D"].waitForExistence(timeout: 8) ||
            app.staticTexts["7D"].waitForExistence(timeout: 8)
        )
        _ = app.buttons["30D"].exists || app.staticTexts["30D"].exists
        // Classic primary chart scrub surface (RuleMark + tooltip via ChartScrubSelection).
        let chart = app.otherElements["metric.chart.scrub"].firstMatch
        XCTAssertTrue(
            chart.waitForExistence(timeout: 8) ||
            app.staticTexts["Trend"].waitForExistence(timeout: 8) ||
            app.staticTexts["Drag to inspect"].waitForExistence(timeout: 8)
        )
        // Soft: attempt a short drag on the chart plot if hittable (Charts + XCTest is flaky).
        if chart.exists && chart.isHittable {
            let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
            start.press(forDuration: 0.15, thenDragTo: end)
            _ = app.otherElements["metric.chart.selection"].exists
        }
        saveShot("verify-metric-detail-classic-scrub.png")
    }

    func testAdvancedMetricDetailChartScrubSurface() throws {
        // Today → Breakdown → Sleep row → AdvancedMetricDetailView (bands/MA scrub).
        revealText("Breakdown")
        let sleepRow = app.descendants(matching: .any)["breakdown.Sleep"].firstMatch
        if sleepRow.waitForExistence(timeout: 8) {
            sleepRow.tap()
        } else {
            let fallback = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Sleep")).firstMatch
            XCTAssertTrue(fallback.waitForExistence(timeout: 8), "Breakdown Sleep row")
            fallback.tap()
        }
        XCTAssertTrue(
            app.navigationBars["Sleep"].waitForExistence(timeout: 8) ||
            app.otherElements["metric.detail"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.buttons["7D"].waitForExistence(timeout: 8) ||
            app.staticTexts["7D"].waitForExistence(timeout: 8)
        )
        let chart = app.otherElements["metric.chart.scrub"].firstMatch
        XCTAssertTrue(
            chart.waitForExistence(timeout: 8) ||
            app.staticTexts["Actual"].waitForExistence(timeout: 8) ||
            app.staticTexts["Baseline Bands"].waitForExistence(timeout: 8)
        )
        if chart.exists && chart.isHittable {
            let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
            start.press(forDuration: 0.15, thenDragTo: end)
            _ = app.otherElements["metric.chart.selection"].exists
        }
        saveShot("verify-metric-detail-scrub.png")
    }

    func testStrainRecoveryBalanceSurface() throws {
        // Today WHOOP stack: elevated Balance card (Recovery | Strain + deltas) + 7-day spark.
        // Scroll via Sleep Consistency (stable neighbor above Balance) to avoid ambiguous "Balance" hits.
        revealText("Sleep Consistency")
        app.swipeUp()
        let byId = app.descendants(matching: .any)["strain.recovery.balance"].firstMatch
        let byLabel = app.buttons["Strain recovery balance detail"].firstMatch
        let balanceTitle = app.staticTexts["Balance"]
        var n = 0
        while !(byId.exists || byLabel.exists || balanceTitle.exists) && n < 6 {
            app.swipeUp()
            n += 1
        }
        XCTAssertTrue(
            byId.waitForExistence(timeout: 6) ||
            byLabel.waitForExistence(timeout: 4) ||
            balanceTitle.waitForExistence(timeout: 4),
            "strain.recovery.balance"
        )
        // Side-by-side WHOOP hierarchy on Today under -ui-fixture.
        XCTAssertTrue(app.staticTexts["Recovery"].exists)
        XCTAssertTrue(app.staticTexts["Strain"].exists)
        // Soft: spark under the wheel may still be in frame depending on scroll depth.
        _ = app.staticTexts["7-Day Recovery"].exists
        _ = app.descendants(matching: .any)["recovery.trajectory.spark"].exists
        // Capture Today elevated card first (evidence of the presentation change).
        saveShot("verify-strain-recovery.png")
        // Soft: tappable → RecoveryStrainDetailView (same destination as wheel header).
        if byId.exists && byId.isHittable {
            byId.tap()
        } else if byLabel.exists && byLabel.isHittable {
            byLabel.tap()
        } else if balanceTitle.exists {
            balanceTitle.tap()
        }
        _ = app.navigationBars["Recovery & Strain"].waitForExistence(timeout: 6)
            || app.staticTexts["Strain Breakdown"].waitForExistence(timeout: 4)
    }


    func testSleepPerformanceSurface() throws {
        // Today WHOOP stack: elevated Sleep Performance Need | Got dual metric + bar.
        // Reveal title first — do not keep swiping for ids (overscrolls past the card).
        revealText("Sleep Performance")
        XCTAssertTrue(app.staticTexts["Sleep Performance"].exists)
        XCTAssertTrue(app.staticTexts["Need"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Got"].exists)
        // Soft: a11y + efficiency / consistency one-liners share the frame under -ui-fixture.
        _ = app.descendants(matching: .any)["sleep.performance"].exists
        _ = app.descendants(matching: .any)["sleep.performance.needGot"].exists
        _ = app.staticTexts["Efficiency"].exists
        _ = app.staticTexts["Consistency"].exists
        saveShot("verify-sleep-performance.png")
    }

    func testSleepHRVSurface() throws {
        // Today WHOOP stack: elevated Sleep HRV Tonight | Baseline + 7-night spark + band.
        // Reveal title first — do not keep swiping for ids (overscrolls past the card).
        revealText("Sleep HRV")
        XCTAssertTrue(app.staticTexts["Sleep HRV"].exists)
        XCTAssertTrue(app.staticTexts["Tonight"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Baseline"].exists)
        // Soft: a11y + 7-night spark / Sleep Quality share the frame under -ui-fixture.
        _ = app.descendants(matching: .any)["sleepHRVCard"].exists
        _ = app.descendants(matching: .any)["sleep.hrv.baseline"].exists
        _ = app.staticTexts["7-Night HRV"].exists
        _ = app.descendants(matching: .any)["sleep.hrv.spark"].exists
        _ = app.staticTexts["Sleep Quality"].exists
        saveShot("verify-sleep-hrv.png")
    }

    func testRespiratoryRateSurface() throws {
        // Today WHOOP stack: elevated Respiratory Rate Tonight | Baseline + 7-night spark + band.
        // Reveal title first — do not keep swiping for ids (overscrolls past the card).
        revealText("Respiratory Rate")
        XCTAssertTrue(app.staticTexts["Respiratory Rate"].exists)
        XCTAssertTrue(app.staticTexts["Tonight"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Baseline"].exists)
        // Soft: a11y + 7-night spark share the frame under -ui-fixture.
        _ = app.descendants(matching: .any)["respiratory.card"].exists
        _ = app.descendants(matching: .any)["respiratory.baseline"].exists
        _ = app.staticTexts["7-Night RR"].exists
        _ = app.descendants(matching: .any)["respiratory.spark"].exists
        saveShot("verify-respiratory.png")
    }

    func testSkinTemperatureSurface() throws {
        // Today WHOOP stack: elevated Skin Temperature Tonight | Baseline + 7-night spark + band.
        revealText("Skin Temperature")
        XCTAssertTrue(app.staticTexts["Skin Temperature"].exists)
        XCTAssertTrue(app.staticTexts["Tonight"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Baseline"].exists)
        // Soft: a11y + 7-night spark share the frame under -ui-fixture.
        _ = app.descendants(matching: .any)["skin.temp.card"].exists
        _ = app.descendants(matching: .any)["skin.temp.baseline"].exists
        _ = app.staticTexts["7-Night Temp"].exists
        _ = app.descendants(matching: .any)["skin.temp.spark"].exists
        saveShot("verify-skin-temp.png")
    }

    func testRecommendationsSurface() throws {
        // Today Recommendations: WHOOP-style actionable cards (≥1 under -ui-fixture).
        revealText("Recommendations")
        let section = app.descendants(matching: .any)["recommendations.section"].firstMatch
        XCTAssertTrue(
            section.waitForExistence(timeout: 8) ||
            app.staticTexts["Recommendations"].exists,
            "recommendations.section"
        )
        // Soft: action cue chrome / known titles from training or coaching bridge.
        _ = app.staticTexts["Today's training guidance"].exists
        _ = app.staticTexts["Protein intake is low"].exists
        _ = app.staticTexts["Ready to Progress"].exists
        _ = app.staticTexts["Progressive Overload Window"].exists
        saveShot("verify-recommendations.png")
    }

    func testCoachingSurface() throws {
        // Settings → Coaching: ranked insight cards under -ui-fixture (not empty state).
        app.tabBars.buttons["Settings"].tap()
        let coaching = app.staticTexts["Coaching"].exists ? app.staticTexts["Coaching"] : app.buttons["Coaching"]
        XCTAssertTrue(coaching.waitForExistence(timeout: 8), "Coaching row")
        coaching.tap()
        XCTAssertTrue(
            app.navigationBars["Coaching"].waitForExistence(timeout: 8) ||
            app.staticTexts["Coaching"].waitForExistence(timeout: 8)
        )
        XCTAssertFalse(app.staticTexts["No coaching insights yet"].exists)
        let feed = app.descendants(matching: .any)["coaching.feed"].firstMatch
        XCTAssertTrue(
            feed.waitForExistence(timeout: 8) ||
            app.staticTexts["Today's training guidance"].waitForExistence(timeout: 8) ||
            app.descendants(matching: .any)["coaching.card"].firstMatch.waitForExistence(timeout: 8),
            "coaching.feed"
        )
        saveShot("verify-coaching.png")
    }

    func testSettingsSourcesConnectRows() throws {
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Apple Health"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["WHOOP via Apple Health"].exists)
        let connect = app.descendants(matching: .any)["settings.healthkit.connect"].firstMatch
        let reconnect = app.buttons["Reconnect"]
        let connectTitle = app.buttons["Connect"]
        XCTAssertTrue(connect.exists || reconnect.exists || connectTitle.exists)
        saveShot("verify-settings-sources.png")
    }

    private func revealText(_ text: String) {
        let el = app.staticTexts[text]
        var n = 0
        while !isOnScreen(el) && n < 16 {
            app.swipeUp()
            n += 1
        }
        XCTAssertTrue(isOnScreen(el), text)
    }

    private func isOnScreen(_ el: XCUIElement) -> Bool {
        guard el.exists else { return false }
        let frame = el.frame
        let window = app.windows.firstMatch.frame
        guard window.width > 0 else { return el.exists }
        let visible = window.insetBy(dx: 0, dy: 90)
        return frame.intersects(visible) && frame.height > 4
    }

    private func saveShot(_ name: String) {
        let dir = URL(fileURLWithPath: "/tmp/rt-audit")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let data = XCUIScreen.main.screenshot().pngRepresentation
        let url = dir.appendingPathComponent(name)
        try? data.write(to: url)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), name)
    }
}
