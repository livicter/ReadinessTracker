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
