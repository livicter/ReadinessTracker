import XCTest
@testable import Readiness

final class GoogleHealthHRVMapperTests: XCTestCase {

    /// Fixture shaped like Google Health API list response for `daily-heart-rate-variability`.
    private let fixtureJSON = """
    {
      "dataPoints": [
        {
          "name": "users/me/dataTypes/daily-heart-rate-variability/dataPoints/hrv-older",
          "dailyHeartRateVariability": {
            "date": { "year": 2026, "month": 9, "day": 28 },
            "averageHeartRateVariabilityMilliseconds": 42.5,
            "deepSleepRootMeanSquareOfSuccessiveDifferencesMilliseconds": 38.0,
            "entropy": 1.2
          }
        },
        {
          "name": "users/me/dataTypes/daily-heart-rate-variability/dataPoints/hrv-today",
          "dailyHeartRateVariability": {
            "date": { "year": 2026, "month": 9, "day": 30 },
            "averageHeartRateVariabilityMilliseconds": 55.75,
            "deepSleepRootMeanSquareOfSuccessiveDifferencesMilliseconds": 49.0,
            "entropy": 1.4
          }
        }
      ]
    }
    """

    func testMapsLatestCivilDateAverageRMSSD() throws {
        let data = Data(fixtureJSON.utf8)
        let ms = try XCTUnwrap(GoogleHealthHRVMapper.mapListResponse(data))
        XCTAssertEqual(ms, 55.75, accuracy: 0.001)
    }

    func testEmptyDataPointsReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [] }"#.utf8)
        XCTAssertNil(try GoogleHealthHRVMapper.mapListResponse(data))
    }

    func testMissingPayloadReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [ { "name": "x" } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthHRVMapper.mapListResponse(data))
    }

    func testStringAndNumberAverageRMSSD() throws {
        let asString = Data(#"""
        { "dataPoints": [ {
            "dailyHeartRateVariability": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averageHeartRateVariabilityMilliseconds": "61.5"
            }
        } ] }
        """#.utf8)
        let asNumber = Data(#"""
        { "dataPoints": [ {
            "dailyHeartRateVariability": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averageHeartRateVariabilityMilliseconds": 62.25
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthHRVMapper.mapListResponse(asString)), 61.5, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthHRVMapper.mapListResponse(asNumber)), 62.25, accuracy: 0.001)
    }

    func testDeepSleepRMSSDFallbackWhenAverageMissing() throws {
        let data = Data(#"""
        { "dataPoints": [ {
            "dailyHeartRateVariability": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "deepSleepRootMeanSquareOfSuccessiveDifferencesMilliseconds": 47.0
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthHRVMapper.mapListResponse(data)), 47.0, accuracy: 0.001)
    }

    func testZeroAverageReturnsNilWithoutDeepFallback() throws {
        let data = Data(#"""
        { "dataPoints": [ {
            "dailyHeartRateVariability": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averageHeartRateVariabilityMilliseconds": 0
            }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthHRVMapper.mapListResponse(data))
    }

    func testCivilRankOrdering() {
        let earlier = GoogleHealthHRVMapper.CivilDate(year: 2026, month: 9, day: 29)
        let later = GoogleHealthHRVMapper.CivilDate(year: 2026, month: 9, day: 30)
        XCTAssertLessThan(
            GoogleHealthHRVMapper.civilRank(earlier),
            GoogleHealthHRVMapper.civilRank(later)
        )
    }
}
