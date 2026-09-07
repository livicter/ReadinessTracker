import XCTest
@testable import Readiness

final class ChartScrubSelectionTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    private func day(_ offset: Int, from base: Date = Date(timeIntervalSince1970: 1_700_000_000)) -> Date {
        cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: base))!
    }

    func testNearestIndexEmpty() {
        XCTAssertNil(ChartScrubSelection.nearestIndex(in: [], to: Date()))
    }

    func testNearestIndexExactAndMidpoint() {
        let dates = [day(0), day(1), day(2), day(3)]
        XCTAssertEqual(ChartScrubSelection.nearestIndex(in: dates, to: day(2)), 2)

        let mid = dates[1].addingTimeInterval(dates[2].timeIntervalSince(dates[1]) / 2)
        // Midpoint ties break toward the earlier index via min(by:).
        let idx = ChartScrubSelection.nearestIndex(in: dates, to: mid)
        XCTAssertTrue(idx == 1 || idx == 2)
    }

    func testNearestIndexClampsToEnds() {
        let dates = [day(0), day(1), day(2)]
        XCTAssertEqual(ChartScrubSelection.nearestIndex(in: dates, to: day(-5)), 0)
        XCTAssertEqual(ChartScrubSelection.nearestIndex(in: dates, to: day(99)), 2)
    }

    func testDateAtFraction() {
        let first = day(0)
        let last = day(10)
        XCTAssertEqual(ChartScrubSelection.date(atFraction: 0, from: first, to: last), first)
        XCTAssertEqual(ChartScrubSelection.date(atFraction: 1, from: first, to: last), last)
        XCTAssertEqual(ChartScrubSelection.date(atFraction: -0.5, from: first, to: last), first)
        XCTAssertEqual(ChartScrubSelection.date(atFraction: 1.5, from: first, to: last), last)

        let mid = ChartScrubSelection.date(atFraction: 0.5, from: first, to: last)
        XCTAssertEqual(mid.timeIntervalSince(first), last.timeIntervalSince(first) / 2, accuracy: 0.001)
    }

    func testCalloutText() {
        let d = day(0)
        let text = ChartScrubSelection.calloutText(date: d, value: "58", unit: "ms")
        XCTAssertTrue(text.contains("58"))
        XCTAssertTrue(text.contains("ms"))
        XCTAssertTrue(text.contains(":"))
    }
}
