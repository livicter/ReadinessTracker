import XCTest
@testable import Readiness

final class AppDeepLinkTests: XCTestCase {
    func testParsesCheckInMorningHostPath() {
        let url = URL(string: "readinesstracker://checkin/morning")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.morning))
    }

    func testParsesCheckInEveningHostPath() {
        let url = URL(string: "readinesstracker://checkin/evening")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.evening))
    }

    func testParsesCheckInEveningQuery() {
        let url = URL(string: "readinesstracker://checkin?time=evening")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.evening))
    }

    func testParsesCheckInBareHostAsMorning() {
        let url = URL(string: "readinesstracker://checkin")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.morning))
    }

    func testParsesTrendsHost() {
        let url = URL(string: "readinesstracker://trends")!
        XCTAssertEqual(AppDeepLink.parse(url), .trends)
    }

    func testParsesTrendsPathFallback() {
        let url = URL(string: "readinesstracker:///trends")!
        XCTAssertEqual(AppDeepLink.parse(url), .trends)
    }

    func testParsesFitbitOAuth() {
        let url = URL(string: "readinesstracker://oauth?code=abc")!
        XCTAssertEqual(AppDeepLink.parse(url), .fitbitOAuth)
    }

    func testRejectsForeignScheme() {
        let url = URL(string: "https://example.com/checkin")!
        XCTAssertNil(AppDeepLink.parse(url))
    }

    func testCheckInMorningURLMatchesScheme() {
        let url = AppDeepLink.checkInMorningURL
        XCTAssertEqual(url.scheme, AppDeepLink.scheme)
        XCTAssertEqual(url.host, AppDeepLink.checkInHost)
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.morning))
    }

    func testCheckInEveningURLMatchesScheme() {
        let url = AppDeepLink.checkInEveningURL
        XCTAssertEqual(url.scheme, AppDeepLink.scheme)
        XCTAssertEqual(url.host, AppDeepLink.checkInHost)
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.evening))
    }

    func testTrendsURLMatchesScheme() {
        let url = AppDeepLink.trendsURL
        XCTAssertEqual(url.scheme, AppDeepLink.scheme)
        XCTAssertEqual(url.host, AppDeepLink.trendsHost)
        XCTAssertEqual(AppDeepLink.parse(url), .trends)
    }
}
