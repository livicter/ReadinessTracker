import XCTest
@testable import Readiness

final class GoogleHealthRHRMapperTests: XCTestCase {

    /// Fixture shaped like Google Health API list response for `daily-resting-heart-rate`.
    private let fixtureJSON = """
    {
      "dataPoints": [
        {
          "name": "users/me/dataTypes/daily-resting-heart-rate/dataPoints/rhr-older",
          "dailyRestingHeartRate": {
            "date": { "year": 2026, "month": 9, "day": 28 },
            "beatsPerMinute": "55",
            "dailyRestingHeartRateMetadata": {
              "calculationMethod": "WITH_SLEEP"
            }
          }
        },
        {
          "name": "users/me/dataTypes/daily-resting-heart-rate/dataPoints/rhr-today",
          "dailyRestingHeartRate": {
            "date": { "year": 2026, "month": 9, "day": 30 },
            "beatsPerMinute": "58",
            "dailyRestingHeartRateMetadata": {
              "calculationMethod": "ONLY_WITH_AWAKE_DATA"
            }
          }
        }
      ]
    }
    """

    func testMapsLatestCivilDateBPM() throws {
        let data = Data(fixtureJSON.utf8)
        let bpm = try XCTUnwrap(GoogleHealthRHRMapper.mapListResponse(data))
        XCTAssertEqual(bpm, 58, accuracy: 0.001)
    }

    func testEmptyDataPointsReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [] }"#.utf8)
        XCTAssertNil(try GoogleHealthRHRMapper.mapListResponse(data))
    }

    func testMissingPayloadReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [ { "name": "x" } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthRHRMapper.mapListResponse(data))
    }

    func testInt64StringAndNumberBPM() throws {
        let asString = Data(#"""
        { "dataPoints": [ {
            "dailyRestingHeartRate": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "beatsPerMinute": "61"
            }
        } ] }
        """#.utf8)
        let asNumber = Data(#"""
        { "dataPoints": [ {
            "dailyRestingHeartRate": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "beatsPerMinute": 62
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthRHRMapper.mapListResponse(asString)), 61, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthRHRMapper.mapListResponse(asNumber)), 62, accuracy: 0.001)
    }

    func testZeroBPMReturnsNil() throws {
        let data = Data(#"""
        { "dataPoints": [ {
            "dailyRestingHeartRate": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "beatsPerMinute": "0"
            }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthRHRMapper.mapListResponse(data))
    }

    func testCivilRankOrdering() {
        let earlier = GoogleHealthRHRMapper.CivilDate(year: 2026, month: 9, day: 29)
        let later = GoogleHealthRHRMapper.CivilDate(year: 2026, month: 9, day: 30)
        XCTAssertLessThan(
            GoogleHealthRHRMapper.civilRank(earlier),
            GoogleHealthRHRMapper.civilRank(later)
        )
    }
}
