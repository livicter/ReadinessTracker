import XCTest
@testable import Readiness

final class AppDeepLinkTests: XCTestCase {
    func testParsesCheckInMorningHostPath() {
        let url = URL(string: "readinesstracker://checkin/morning")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.morning))
    }

    func testParsesCheckInEveningQuery() {
        let url = URL(string: "readinesstracker://checkin?time=evening")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.evening))
    }

    func testParsesCheckInBareHostAsMorning() {
        let url = URL(string: "readinesstracker://checkin")!
        XCTAssertEqual(AppDeepLink.parse(url), .checkIn(.morning))
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
}
