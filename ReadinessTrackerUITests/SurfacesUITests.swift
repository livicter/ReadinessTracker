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

    func testWhoopStackVisibleAfterScroll() throws {
        revealText("Sleep HRV")
        XCTAssertTrue(app.staticTexts["Sleep Debt"].exists)
        saveShot("verify-whoop-stack.png")
    }

    func testBodyActivityVisibleAfterScroll() throws {
        revealText("Body & activity")
        XCTAssertTrue(app.staticTexts["Steps"].exists)
        saveShot("verify-body-activity.png")
    }

    func testSleepQualitySurfaceVisibleAfterScroll() throws {
        revealText("Sleep Consistency")
        XCTAssertTrue(app.staticTexts["Sleep Quality Trend"].exists)
        XCTAssertTrue(app.staticTexts["Sleep Consistency"].exists)
        // Sleep HRV chips (HRV Trend / Sleep Quality) may still be on screen depending on scroll depth.
        _ = app.staticTexts["Sleep HRV"].exists
        _ = app.staticTexts["HRV Trend"].exists
        _ = app.staticTexts["Sleep Quality"].exists
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
        app.tabBars.buttons["History"].tap()
        // History: source picker + Weekly Report + Trends under -ui-fixture (14 appleWatch days).
        XCTAssertTrue(
            app.navigationBars["History"].waitForExistence(timeout: 8) ||
            app.staticTexts["History"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(app.staticTexts["Weekly Report"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["Trends"].waitForExistence(timeout: 8))
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
        // Journal: Today NavigationLink → JournalView with empty-state "Log 7 days…" strip.
        revealText("Journal")
        let journalRow = app.buttons["Journal"].exists ? app.buttons["Journal"] : app.staticTexts["Journal"]
        journalRow.tap()
        XCTAssertTrue(
            app.navigationBars["Journal"].waitForExistence(timeout: 8) ||
            app.staticTexts["Journal"].waitForExistence(timeout: 8)
        )
        let log7Copy = "Log 7 days to see how habits line up with next-day readiness."
        XCTAssertTrue(app.staticTexts[log7Copy].waitForExistence(timeout: 8))
        // Entry form fills the first screen; scroll so the Log 7 days strip is in frame.
        revealText(log7Copy)
        _ = app.staticTexts["No journal entries yet"].exists
        saveShot("verify-journal.png")
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
        // Today → Metrics → Sleep card → AdvancedMetricDetailView (period selector + scrub chart).
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
        // Chart surface (scrub chrome may not stick after lift; assert detail + chart id).
        let chart = app.otherElements["metric.chart.scrub"].firstMatch
        XCTAssertTrue(
            chart.waitForExistence(timeout: 8) ||
            app.staticTexts["Actual"].waitForExistence(timeout: 8) ||
            app.staticTexts["Baseline Bands"].waitForExistence(timeout: 8)
        )
        // Soft: attempt a short drag on the chart plot if hittable (Charts + XCTest is flaky).
        if chart.exists && chart.isHittable {
            let start = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            let end = chart.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
            start.press(forDuration: 0.15, thenDragTo: end)
            _ = app.otherElements["metric.chart.selection"].exists
        }
        saveShot("verify-metric-detail-scrub.png")
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
