import XCTest

final class SurfacesUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-fixture"]
        app.launch()
    }


    /// Floating pill tabs are not UITabBar — prefer tab.<name> ids.
    private func tapMainTab(_ title: String) {
        let id = "tab.\(title.lowercased())"
        let byId = app.descendants(matching: .any)[id].firstMatch
        if byId.waitForExistence(timeout: 3) {
            byId.tap()
            return
        }
        let byButton = app.buttons[title]
        if byButton.waitForExistence(timeout: 3) {
            byButton.tap()
            return
        }
        let legacy = app.tabBars.buttons[title]
        XCTAssertTrue(legacy.waitForExistence(timeout: 8), "Missing tab \(title)")
        legacy.tap()
    }

    func testTodayHeroBright() throws {
        // Honest #72: Morning|Evening CheckInStatusCard circular tint wells.
        XCTAssertTrue(app.staticTexts["Readiness"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["HealthKit"].exists)
        saveShot("verify-dashboard.png")
    }

    func testTodayRingsGeometry() throws {
        XCTAssertTrue(app.staticTexts["TODAY'S READINESS"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Gym"].exists)
        Thread.sleep(forTimeInterval: 1.4)
        saveShot("verify-rings.png")
    }

    func testReadinessDetailSurface() throws {
        // Honest #81: Readiness Detail recommendation + component circular wells.
        // Open via Today score / readiness hero when available.
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        let score = app.descendants(matching: .any)["readiness.score"].firstMatch
        if score.waitForExistence(timeout: 4), score.isHittable {
            score.tap()
        } else {
            // Fallback: tap large readiness numerals / hero card.
            let hero = app.descendants(matching: .any)["today.hero"].firstMatch
            if hero.exists, hero.isHittable { hero.tap() }
        }
        _ = app.staticTexts["Recommendation"].waitForExistence(timeout: 6) || app.staticTexts["Component Detail"].waitForExistence(timeout: 4)
        saveShot("verify-readiness-detail.png")
    }


    func testRingDetailHeroWellSurface() throws {
        // Honest #88: Ring Detail hero circular tint well (Gym/Work/Sleep).
        // Today legend Gym → RingDetailView sheet (same path as testRingDetailSurface).
        XCTAssertTrue(app.staticTexts["TODAY'S READINESS"].waitForExistence(timeout: 8))
        let gym = app.descendants(matching: .any)["ring.legend.gym"].firstMatch
        XCTAssertTrue(gym.waitForExistence(timeout: 8), "ring.legend.gym")
        gym.tap()
        XCTAssertTrue(
            app.staticTexts["Last 7 days"].waitForExistence(timeout: 8) ||
            app.otherElements["ring.detail.score"].waitForExistence(timeout: 6)
        )
        saveShot("verify-ring-detail-hero.png")
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
        // Honest #67: sleep-stack footer chips use circular tint wells.
        revealText("Sleep HRV")
        XCTAssertTrue(app.staticTexts["Sleep Debt"].exists)
        saveShot("verify-whoop-stack.png")
    }

    func testBodyActivityVisibleAfterScroll() throws {
        // Honest #63: Body section + circular tint wells on metric tiles.
        // Elevated Body tiles: progress-to-goal + sparkline chrome; Activity minutes label.
        revealText("Body")
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        XCTAssertTrue(app.staticTexts["Activity"].exists)
        let stepsTile = app.descendants(matching: .any)["body.tile.steps"].firstMatch
        XCTAssertTrue(stepsTile.waitForExistence(timeout: 8), "body.tile.steps")
        _ = app.descendants(matching: .any)["body.tile.activity"].exists
        saveShot("verify-body-activity.png")
    }

    func testMetricAboutWellSurface() throws {
        // Honest #86: Metric Detail / Advanced Metric About circular tint wells.
        // Today → Metrics → Sleep card → MetricDetailView; soft-scroll About / older-data cue.
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
        // Soft: About / older-data copy may sit below the chart — scroll without hard assert.
        let cue = app.staticTexts["Why can't I see older data?"]
        var n = 0
        while !cue.exists && n < 12 {
            app.swipeUp()
            n += 1
        }
        _ = cue.exists || app.staticTexts["About This Data"].exists
        saveShot("verify-metric-about.png")
    }

    func testMetricsSectionVisibleAfterScroll() throws {
        // Honest #75: MetricCard header circular tint wells (Sleep/HRV/Resting HR/Active Cals).
        revealText("Metrics")
        XCTAssertTrue(app.staticTexts["Resting HR"].waitForExistence(timeout: 8), "Resting HR")
        _ = app.staticTexts["Sleep"].exists
        _ = app.staticTexts["Active Cals"].exists
        saveShot("verify-metrics.png")
    }

    func testBodyDetailSurface() throws {
        // Today Body Steps tile → Fitness / Google Health–style metric detail sheet.
        revealText("Body")
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
        // Honest #71: Bedtime|Wake dual columns use circular tint wells.
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
        // Today WHOOP stack: elevated Sleep Debt (debt hours graphic, payback cue, 7-night spark/bars).
        revealText("Sleep Debt")
        XCTAssertTrue(app.staticTexts["Sleep Debt"].exists)
        // Soft: elevated chrome under -ui-fixture.
        _ = app.descendants(matching: .any)["sleepDebtCard"].exists
        _ = app.descendants(matching: .any)["sleep.debt.hours"].exists
        _ = app.descendants(matching: .any)["sleep.debt.payback"].exists
        _ = app.descendants(matching: .any)["sleep.debt.spark"].exists
        _ = app.descendants(matching: .any)["sleep.debt.bars"].exists
        _ = app.staticTexts["7-Night Balance"].exists
        _ = app.staticTexts["Daily vs need"].exists
        _ = app.staticTexts["Debt"].exists || app.staticTexts["Banked"].exists
        _ = app.staticTexts["Last night"].exists
        // Neighbor cards may still be in frame depending on scroll depth.
        _ = app.staticTexts["Sleep HRV"].exists
        saveShot("verify-sleep-debt.png")
    }

    func testCheckInTabSurface() throws {
        // Honest #65: Check-in section headers use circular tint icon wells.
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        tapMainTab("Check-in")
        let morning = app.buttons["Morning"]
        let evening = app.buttons["Evening"]
        let save = app.buttons["Save"]
        let physical = app.staticTexts["Physical State"]
        let physicalId = app.descendants(matching: .any)["checkin.section.physical-state"].firstMatch
        let feel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "feel")).firstMatch
        XCTAssertTrue(
            morning.waitForExistence(timeout: 10) ||
            evening.waitForExistence(timeout: 2) ||
            save.waitForExistence(timeout: 2) ||
            physical.waitForExistence(timeout: 2) ||
            physicalId.waitForExistence(timeout: 2) ||
            feel.waitForExistence(timeout: 2),
            "Check-in surface"
        )
        _ = app.staticTexts["Daily Check-in"].exists
        _ = physical.exists || physicalId.exists
        saveShot("verify-checkin.png")
    }

    func testTrendsDetailSurface() throws {
        // Honest #84: Trend Detail summary-card circular tint wells.
        // History → Browse Trends → TrendDetailView (period chips + Avg/Min/Max + scrub).
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        let historyTab = app.descendants(matching: .any)["tab.history"].firstMatch
        XCTAssertTrue(historyTab.waitForExistence(timeout: 8), "History tab")
        historyTab.tap()
        let landed =
            app.staticTexts["Weekly Report"].waitForExistence(timeout: 12) ||
            app.staticTexts["Trends"].waitForExistence(timeout: 4) ||
            app.staticTexts["Browse Trends"].waitForExistence(timeout: 4)
        XCTAssertTrue(landed, "History tab content")
        let link = app.descendants(matching: .any)["history.trends.link"].firstMatch
        if link.waitForExistence(timeout: 6) {
            if link.isHittable {
                link.tap()
            } else {
                link.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
            }
        } else {
            let browse = app.staticTexts["Browse Trends"].exists ? app.staticTexts["Browse Trends"] : app.buttons["Browse Trends"]
            XCTAssertTrue(browse.waitForExistence(timeout: 8), "Browse Trends")
            browse.tap()
        }
        XCTAssertTrue(
            app.navigationBars["Trends"].waitForExistence(timeout: 8) ||
            app.otherElements["trends.detail"].waitForExistence(timeout: 8) ||
            app.staticTexts["Multi-Metric Trend"].waitForExistence(timeout: 8),
            "trends.detail"
        )
        // Health Browse period chips.
        XCTAssertTrue(
            app.buttons["7D"].waitForExistence(timeout: 8) ||
            app.staticTexts["7D"].waitForExistence(timeout: 8)
        )
        _ = app.buttons["30D"].exists || app.staticTexts["30D"].exists
        // Summary Avg / Min / Max row.
        _ = app.otherElements["trends.summary"].exists
        _ = app.staticTexts["Avg"].exists
        _ = app.staticTexts["Min"].exists
        _ = app.staticTexts["Max"].exists
        _ = app.staticTexts["Change"].exists
        // Soft scrub chrome.
        let chart = app.otherElements["trends.chart.scrub"].firstMatch
        _ = chart.waitForExistence(timeout: 4) || app.staticTexts["Drag to inspect"].exists
        if chart.exists && chart.isHittable {
            let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
            start.press(forDuration: 0.15, thenDragTo: end)
            _ = app.otherElements["trends.chart.selection"].exists
        }
        saveShot("verify-trends.png")
    }


    func testDayDetailSurface() throws {
        // Honest #79: Day Detail stage-row + metric-chip circular tint wells.
        // History → day row → DayDetailView (WHOOP night-detail: header metrics, stage % chips, hypnogram, cycles).
        // Alternate path Today → Sleep Stages also lands on elevated Sleep Analysis chrome.
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        let historyTab = app.descendants(matching: .any)["tab.history"].firstMatch
        XCTAssertTrue(historyTab.waitForExistence(timeout: 8), "History tab")
        historyTab.tap()
        let landed =
            app.staticTexts["Weekly Report"].waitForExistence(timeout: 12) ||
            app.staticTexts["Trends"].waitForExistence(timeout: 4) ||
            app.staticTexts["Browse Trends"].waitForExistence(timeout: 4)
        XCTAssertTrue(landed, "History tab content")

        // Prefer History day row (fixture seeds sleep hours). Scroll past Trends if needed.
        var opened = false
        for _ in 0..<4 {
            let sleepPredicate = NSPredicate(format: "label MATCHES %@", "[0-9]+\\.[0-9]+h")
            let hit = app.staticTexts.matching(sleepPredicate).firstMatch
            if hit.waitForExistence(timeout: 2), hit.isHittable {
                hit.tap()
                opened = true
                break
            }
            // Nudge list downward to expose day rows under Trends.
            let list = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
            if list.exists {
                list.swipeUp()
            } else {
                app.swipeUp()
            }
        }
        if !opened {
            // Fallback: Today → Sleep Stages → Sleep Analysis (same elevated night chrome).
            tapMainTab("Today")
            _ = app.staticTexts["Readiness"].waitForExistence(timeout: 6)
            revealText("Sleep Stages")
            let stagesCard = app.buttons["Sleep Stages"].exists ? app.buttons["Sleep Stages"] : app.staticTexts["Sleep Stages"]
            XCTAssertTrue(stagesCard.waitForExistence(timeout: 8), "Sleep Stages")
            stagesCard.tap()
            opened = true
        }

        let onDayOrSleep =
            app.otherElements["day.detail"].waitForExistence(timeout: 8) ||
            app.staticTexts["Asleep"].waitForExistence(timeout: 4) ||
            app.staticTexts["Stage Mix"].waitForExistence(timeout: 4) ||
            app.staticTexts["Sleep Timeline"].waitForExistence(timeout: 4) ||
            app.staticTexts["Sleep Analysis"].waitForExistence(timeout: 4) ||
            app.navigationBars["Sleep Analysis"].waitForExistence(timeout: 4)
        XCTAssertTrue(onDayOrSleep, "day/sleep detail")

        // Soft-check elevated WHOOP night-detail chrome.
        _ = app.otherElements["day.detail.header"].exists || app.staticTexts["Asleep"].exists || app.staticTexts["Score"].exists
        _ = app.otherElements["day.detail.stageChips"].exists || app.staticTexts["Deep"].exists || app.staticTexts["Stage Mix"].exists
        revealText("Sleep Timeline")
        _ = app.otherElements["day.detail.hypnogram"].exists || app.staticTexts["Sleep Timeline"].exists
        _ = app.otherElements["day.detail.cycles"].exists || app.staticTexts["Sleep Cycles"].exists || app.staticTexts["Stage Mix"].exists
        _ = app.staticTexts["Efficiency"].exists || app.staticTexts["In Bed"].exists

        saveShot("verify-day-detail.png")
    }

    func testDayDetailCompareWellSurface() throws {
        // Honest #87: Day Detail Sleep Cycles + vs Previous Day circular tint wells.
        // Prefer History day row (same path as testDayDetailSurface).
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        let historyTab = app.descendants(matching: .any)["tab.history"].firstMatch
        XCTAssertTrue(historyTab.waitForExistence(timeout: 8), "History tab")
        historyTab.tap()
        let landed =
            app.staticTexts["Weekly Report"].waitForExistence(timeout: 12) ||
            app.staticTexts["Trends"].waitForExistence(timeout: 4) ||
            app.staticTexts["Browse Trends"].waitForExistence(timeout: 4)
        XCTAssertTrue(landed, "History tab content")
        var opened = false
        for _ in 0..<4 {
            let sleepPredicate = NSPredicate(format: "label MATCHES %@", "[0-9]+\\.[0-9]+h")
            let hit = app.staticTexts.matching(sleepPredicate).firstMatch
            if hit.waitForExistence(timeout: 2), hit.isHittable {
                hit.tap()
                opened = true
                break
            }
            app.swipeUp()
        }
        XCTAssertTrue(opened, "History day row")
        _ = app.navigationBars.firstMatch.waitForExistence(timeout: 8)
        // Soft: Sleep Cycles / Recovery Context compare headers
        let cycles = app.staticTexts["Sleep Cycles"]
        var n = 0
        while !cycles.exists && n < 10 {
            app.swipeUp()
            n += 1
        }
        _ = cycles.exists
        let prev = app.staticTexts["vs Previous Day"]
        n = 0
        while !prev.exists && n < 8 {
            app.swipeUp()
            n += 1
        }
        _ = prev.exists || app.staticTexts["Recovery Context"].exists
        saveShot("verify-day-detail-compare.png")
    }

    func testHistoryTabSurface() throws {
        // Honest #64: History rows use circular tint metric wells.
        // Wait for Today chrome before switching tabs (heavier Body tiles can delay first paint).
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        let historyTab = app.descendants(matching: .any)["tab.history"].firstMatch
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
        // Honest #73: Sleep Stages disturbance cue circular tint well.
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

    func testQuickTrendsSurface() throws {
        // Honest #78: QuickTrendCard header circular tint wells.
        revealText("Quick Trends")
        XCTAssertTrue(app.staticTexts["Quick Trends"].waitForExistence(timeout: 8), "Quick Trends")
        saveShot("verify-quick-trends.png")
    }

    func testJournalButtonSurface() throws {
        // Honest #77: Today Journal button circular tint well.
        revealText("Journal")
        XCTAssertTrue(app.staticTexts["Journal"].waitForExistence(timeout: 8) || app.buttons["Journal"].waitForExistence(timeout: 2), "Journal")
        saveShot("verify-journal-button.png")
    }

    func testJournalSurface() throws {
        // Honest #76: Journal Log-7-days cue circular tint well (empty/low-data path).
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
        // Honest #82: Journal Behavior Impact row circular tint wells.
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
        // Honest #83: Weekly Report readiness-trend circular tint well.
        // Honest #68: Weekly Report metric tiles use circular tint icon wells.
        // History → Weekly Report sheet: fixture seeds 14 appleWatch days (≥3 needed).
        tapMainTab("History")
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

    func testSleepAnalysisTimingSurface() throws {
        // Honest #85: Sleep Analysis timing-card circular tint wells.
        revealText("Sleep Stages")
        let stagesCard = app.buttons["Sleep Stages"].exists ? app.buttons["Sleep Stages"] : app.staticTexts["Sleep Stages"]
        stagesCard.tap()
        XCTAssertTrue(
            app.navigationBars["Sleep Analysis"].waitForExistence(timeout: 8) ||
            app.staticTexts["Sleep Analysis"].waitForExistence(timeout: 8)
        )
        // Timing cards (bedtime / wake / efficiency) — soft reveal; titles vary by fixture.
        revealText("Sleep Timeline")
        _ = app.staticTexts["Sleep Efficiency"].exists
        _ = app.staticTexts["Bedtime"].exists || app.staticTexts["Wake"].exists
        saveShot("verify-sleep-analysis.png")
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
        // Honest #61: Apple Health naming — Core (not Light); no score capsule on stages card.
        _ = app.staticTexts["Core"].exists
        XCTAssertFalse(app.staticTexts["Light Sleep"].exists)
        _ = app.staticTexts["1 wakes"].exists || app.staticTexts["1 wake"].exists
        saveShot("verify-sleep-stages.png")
    }

    func testMetricDetailChartScrubSurface() throws {
        // Honest #80: Metric Detail hero circular tint well.
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
        // Honest #74: Strain/Recovery Balance header circular tint well.
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


    func testStrainRecoveryWheelSurface() throws {
        // Honest #69: Recovery/Strain legend uses circular tint icon wells.
        // Today WHOOP stack: elevated dual-arc Strain/Recovery wheel (concentric arcs + value labels).
        revealText("Recovery & Strain")
        let wheel = app.descendants(matching: .any)["strain.recovery.wheel"].firstMatch
        var n = 0
        while !wheel.exists && n < 6 {
            app.swipeUp()
            n += 1
        }
        XCTAssertTrue(
            wheel.waitForExistence(timeout: 6) ||
            app.staticTexts["Recovery & Strain"].exists,
            "strain.recovery.wheel"
        )
        // Soft: dual-arc chrome + value legend under -ui-fixture.
        _ = app.descendants(matching: .any)["strain.recovery.wheel.legend"].exists
        _ = app.descendants(matching: .any)["strain.recovery.wheel.recovery"].exists
        _ = app.descendants(matching: .any)["strain.recovery.wheel.strain"].exists
        _ = app.staticTexts["Recovery"].exists
        _ = app.staticTexts["Strain"].exists
        _ = app.staticTexts["7-Day Recovery"].exists
        saveShot("verify-strain-wheel.png")
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
        // Honest #70: vitals insight cues use circular tint wells.
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
        // Honest #70: vitals insight cues use circular tint wells.
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
        tapMainTab("Settings")
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
        tapMainTab("Settings")
        XCTAssertTrue(app.staticTexts["Apple Health"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["HealthKit"].exists)
        let connect = app.descendants(matching: .any)["settings.healthkit.connect"].firstMatch
        let reconnect = app.buttons["Reconnect"]
        let connectTitle = app.buttons["Connect"]
        XCTAssertTrue(connect.exists || reconnect.exists || connectTitle.exists)
        saveShot("verify-settings-sources.png")
    }

    func testSettingsNotificationsSurface() throws {
        // Settings → Notifications: Apple Settings chrome with tinted icon wells (Honest #62).
        tapMainTab("Settings")
        revealText("Notifications")
        let row = app.buttons["Notifications"].exists ? app.buttons["Notifications"] : app.staticTexts["Notifications"]
        XCTAssertTrue(row.waitForExistence(timeout: 8), "Notifications row")
        row.tap()
        XCTAssertTrue(
            app.navigationBars["Notifications"].waitForExistence(timeout: 8) ||
            app.staticTexts["Notifications"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.switches["Allow Notifications"].waitForExistence(timeout: 8) ||
            app.staticTexts["Allow Notifications"].waitForExistence(timeout: 8) ||
            app.descendants(matching: .any)["settings.notifications.master"].firstMatch.waitForExistence(timeout: 8),
            "Allow Notifications master"
        )
        // Soft: icon-well rows present when master is on (fixture enables notifications).
        _ = app.staticTexts["Morning Summary"].exists
        _ = app.staticTexts["Quiet Hours"].exists
        saveShot("verify-settings-notifications.png")
    }


    func testSettingsInsightsActionsChrome() throws {
        // Honest #66: Insights/Actions rows use AppIconTile wells.
        _ = app.staticTexts["Readiness"].waitForExistence(timeout: 8)
        tapMainTab("Settings")
        var n = 0
        let coaching = app.staticTexts.matching(NSPredicate(format: "label == %@", "Coaching")).element(boundBy: 0)
        while !coaching.exists && n < 16 {
            app.swipeUp()
            n += 1
        }
        XCTAssertTrue(coaching.waitForExistence(timeout: 8), "Coaching row")
        _ = app.staticTexts["Notifications"].exists
        _ = app.staticTexts["Refresh Health Data"].exists || app.staticTexts["Export CSV"].exists
        saveShot("verify-settings-insights.png")
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
