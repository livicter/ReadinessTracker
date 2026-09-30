import XCTest
@testable import Readiness

final class GoogleHealthSpO2MapperTests: XCTestCase {

    /// Fixture shaped like Google Health API list response for `daily-oxygen-saturation`.
    private let fixtureJSON = """
    {
      "dataPoints": [
        {
          "name": "users/me/dataTypes/daily-oxygen-saturation/dataPoints/spo2-older",
          "dailyOxygenSaturation": {
            "date": { "year": 2026, "month": 9, "day": 28 },
            "averagePercentage": 96.2,
            "lowerBoundPercentage": 94.0,
            "upperBoundPercentage": 98.0,
            "standardDeviationPercentage": 1.1
          }
        },
        {
          "name": "users/me/dataTypes/daily-oxygen-saturation/dataPoints/spo2-today",
          "dailyOxygenSaturation": {
            "date": { "year": 2026, "month": 9, "day": 30 },
            "averagePercentage": 97.5,
            "lowerBoundPercentage": 95.5,
            "upperBoundPercentage": 99.0,
            "standardDeviationPercentage": 0.9
          }
        }
      ]
    }
    """

    func testMapsLatestCivilDateAveragePercentage() throws {
        let data = Data(fixtureJSON.utf8)
        let pct = try XCTUnwrap(GoogleHealthSpO2Mapper.mapListResponse(data))
        XCTAssertEqual(pct, 97.5, accuracy: 0.001)
    }

    func testEmptyDataPointsReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [] }"#.utf8)
        XCTAssertNil(try GoogleHealthSpO2Mapper.mapListResponse(data))
    }

    func testMissingPayloadReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [ { "name": "x" } ] }"#.utf8)
        XCTAssertNil(try GoogleHealthSpO2Mapper.mapListResponse(data))
    }

    func testStringAndNumberAveragePercentage() throws {
        let asString = Data(#"""
        { "dataPoints": [ {
            "dailyOxygenSaturation": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averagePercentage": "96.5"
            }
        } ] }
        """#.utf8)
        let asNumber = Data(#"""
        { "dataPoints": [ {
            "dailyOxygenSaturation": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averagePercentage": 98.25
            }
        } ] }
        """#.utf8)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthSpO2Mapper.mapListResponse(asString)), 96.5, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(GoogleHealthSpO2Mapper.mapListResponse(asNumber)), 98.25, accuracy: 0.001)
    }

    func testZeroOrOutOfRangeReturnsNil() throws {
        let zero = Data(#"""
        { "dataPoints": [ {
            "dailyOxygenSaturation": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averagePercentage": 0
            }
        } ] }
        """#.utf8)
        let over = Data(#"""
        { "dataPoints": [ {
            "dailyOxygenSaturation": {
              "date": { "year": 2026, "month": 1, "day": 2 },
              "averagePercentage": 100.1
            }
        } ] }
        """#.utf8)
        XCTAssertNil(try GoogleHealthSpO2Mapper.mapListResponse(zero))
        XCTAssertNil(try GoogleHealthSpO2Mapper.mapListResponse(over))
    }

    func testCivilRankOrdering() {
        let earlier = GoogleHealthSpO2Mapper.CivilDate(year: 2026, month: 9, day: 29)
        let later = GoogleHealthSpO2Mapper.CivilDate(year: 2026, month: 9, day: 30)
        XCTAssertLessThan(
            GoogleHealthSpO2Mapper.civilRank(earlier),
            GoogleHealthSpO2Mapper.civilRank(later)
        )
    }
}
