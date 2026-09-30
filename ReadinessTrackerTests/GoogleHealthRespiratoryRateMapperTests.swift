import XCTest
@testable import Readiness

final class GoogleHealthRespiratoryRateMapperTests: XCTestCase {

    private let fixtureJSON = """
    {
      "dataPoints": [
        {
          "name": "users/me/dataTypes/daily-respiratory-rate/dataPoints/rr-older",
          "dailyRespiratoryRate": {
            "date": { "year": 2026, "month": 9, "day": 28 },
            "breathsPerMinute": 14.2
          }
        },
        {
          "name": "users/me/dataTypes/daily-respiratory-rate/dataPoints/rr-today",
          "dailyRespiratoryRate": {
            "date": { "year": 2026, "month": 9, "day": 30 },
            "breathsPerMinute": 15.75
          }
        }
      ]
    }
    """

    func testMapsLatestCivilDateBreathsPerMinute() throws {
        let bpm = try XCTUnwrap(GoogleHealthRespiratoryRateMapper.mapListResponse(Data(fixtureJSON.utf8)))
        XCTAssertEqual(bpm, 15.75, accuracy: 0.001)
    }

    func testEmptyDataPointsReturnsNil() throws {
        XCTAssertNil(try GoogleHealthRespiratoryRateMapper.mapListResponse(Data(#"{ "dataPoints": [] }"#.utf8)))
    }

    func testMissingPayloadReturnsNil() throws {
        XCTAssertNil(try GoogleHealthRespiratoryRateMapper.mapListResponse(Data(#"{ "dataPoints": [ { "name": "x" } ] }"#.utf8)))
    }

    func testStringBreathsPerMinute() throws {
        let data = Data(#"""
        { "dataPoints": [ {
            "dailyRespiratoryRate": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "breathsPerMinute": "16.5"
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthRespiratoryRateMapper.mapListResponse(data)), 16.5, accuracy: 0.001)
    }

    func testZeroOrOutOfRangeReturnsNil() throws {
        let zero = Data(#"""
        { "dataPoints": [ {
            "dailyRespiratoryRate": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "breathsPerMinute": 0
            }
        } ] }
        """#.utf8)
        let high = Data(#"""
        { "dataPoints": [ {
            "dailyRespiratoryRate": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "breathsPerMinute": 90
            }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthRespiratoryRateMapper.mapListResponse(zero))
        XCTAssertNil(try GoogleHealthRespiratoryRateMapper.mapListResponse(high))
    }

    func testCivilRankOrdering() {
        let earlier = GoogleHealthRespiratoryRateMapper.CivilDate(year: 2026, month: 9, day: 29)
        let later = GoogleHealthRespiratoryRateMapper.CivilDate(year: 2026, month: 9, day: 30)
        XCTAssertLessThan(
            GoogleHealthRespiratoryRateMapper.civilRank(earlier),
            GoogleHealthRespiratoryRateMapper.civilRank(later)
        )
    }
}
