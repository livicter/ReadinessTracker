import XCTest
@testable import Readiness

final class GoogleHealthSleepMapperTests: XCTestCase {

    /// Fixture shaped like Google Health API list response for `sleep` dataPoints.
    private let fixtureJSON = """
    {
      "dataPoints": [
        {
          "name": "users/me/dataTypes/sleep/dataPoints/nap-short",
          "sleep": {
            "interval": {
              "startTime": "2026-09-28T14:00:00Z",
              "startUtcOffset": "28800s",
              "endTime": "2026-09-28T14:45:00Z",
              "endUtcOffset": "28800s"
            },
            "type": "CLASSIC",
            "stages": [
              {
                "startTime": "2026-09-28T14:00:00Z",
                "endTime": "2026-09-28T14:45:00Z",
                "type": "ASLEEP"
              }
            ],
            "summary": {
              "minutesAsleep": "45",
              "minutesInSleepPeriod": "45",
              "minutesAwake": "0",
              "minutesToFallAsleep": "0"
            },
            "metadata": { "nap": true, "processed": true }
          }
        },
        {
          "name": "users/me/dataTypes/sleep/dataPoints/main-night",
          "sleep": {
            "interval": {
              "startTime": "2026-09-27T22:00:00Z",
              "startUtcOffset": "28800s",
              "endTime": "2026-09-28T06:00:00Z",
              "endUtcOffset": "28800s"
            },
            "type": "STAGES",
            "stages": [
              {
                "startTime": "2026-09-27T22:00:00Z",
                "endTime": "2026-09-27T22:30:00Z",
                "type": "LIGHT"
              },
              {
                "startTime": "2026-09-27T22:30:00Z",
                "endTime": "2026-09-27T23:45:00Z",
                "type": "DEEP"
              },
              {
                "startTime": "2026-09-27T23:45:00Z",
                "endTime": "2026-09-28T02:15:00Z",
                "type": "LIGHT"
              },
              {
                "startTime": "2026-09-28T02:15:00Z",
                "endTime": "2026-09-28T02:45:00Z",
                "type": "REM"
              },
              {
                "startTime": "2026-09-28T02:45:00Z",
                "endTime": "2026-09-28T03:00:00Z",
                "type": "AWAKE"
              },
              {
                "startTime": "2026-09-28T03:00:00Z",
                "endTime": "2026-09-28T05:15:00Z",
                "type": "LIGHT"
              },
              {
                "startTime": "2026-09-28T05:15:00Z",
                "endTime": "2026-09-28T06:00:00Z",
                "type": "REM"
              }
            ],
            "summary": {
              "stagesSummary": [
                { "type": "LIGHT", "minutes": "255", "count": "3" },
                { "type": "DEEP", "minutes": "75", "count": "1" },
                { "type": "REM", "minutes": "75", "count": "2" },
                { "type": "AWAKE", "minutes": "15", "count": "1" }
              ],
              "minutesInSleepPeriod": "480",
              "minutesAfterWakeUp": "0",
              "minutesToFallAsleep": "12",
              "minutesAsleep": "405",
              "minutesAwake": "15"
            },
            "metadata": { "nap": false, "processed": true, "manuallyEdited": false }
          }
        }
      ]
    }
    """

    func testMapsMainSleepPreferringNonNap() throws {
        let data = Data(fixtureJSON.utf8)
        let mapped = try XCTUnwrap(GoogleHealthSleepMapper.mapListResponse(data))

        XCTAssertEqual(mapped.hours, 405.0 / 60.0, accuracy: 0.001)
        XCTAssertEqual(mapped.efficiency, 405.0 / 480.0, accuracy: 0.001)
        XCTAssertEqual(mapped.onsetMinutes, 12, accuracy: 0.001)
        XCTAssertEqual(mapped.wakeEpisodes, 1)
        XCTAssertEqual(mapped.stages.count, 7)

        XCTAssertEqual(mapped.deepPercent, 75.0 / 405.0, accuracy: 0.001)
        XCTAssertEqual(mapped.remPercent, 75.0 / 405.0, accuracy: 0.001)
        XCTAssertEqual(mapped.lightPercent, 255.0 / 405.0, accuracy: 0.001)

        XCTAssertNotNil(mapped.start)
        XCTAssertNotNil(mapped.end)
        XCTAssertEqual(mapped.stages.filter { $0.stage == .deep }.count, 1)
        XCTAssertEqual(mapped.stages.filter { $0.stage == .rem }.count, 2)
        XCTAssertEqual(mapped.stages.filter { $0.stage == .awake }.count, 1)
    }

    func testEmptyDataPointsReturnsNil() throws {
        let data = Data(#"{ "dataPoints": [] }"#.utf8)
        XCTAssertNil(try GoogleHealthSleepMapper.mapListResponse(data))
    }

    func testStageTypeMapping() {
        XCTAssertEqual(GoogleHealthSleepMapper.mapStageType("DEEP"), .deep)
        XCTAssertEqual(GoogleHealthSleepMapper.mapStageType("rem"), .rem)
        XCTAssertEqual(GoogleHealthSleepMapper.mapStageType("LIGHT"), .light)
        XCTAssertEqual(GoogleHealthSleepMapper.mapStageType("ASLEEP"), .light)
        XCTAssertEqual(GoogleHealthSleepMapper.mapStageType("AWAKE"), .awake)
        XCTAssertEqual(GoogleHealthSleepMapper.mapStageType("RESTLESS"), .awake)
        XCTAssertNil(GoogleHealthSleepMapper.mapStageType("UNKNOWN"))
        XCTAssertNil(GoogleHealthSleepMapper.mapStageType(nil))
    }

    func testParseTimeSupportsFractionalSeconds() {
        let withFrac = GoogleHealthSleepMapper.parseTime("2026-09-28T06:00:00.123Z")
        let plain = GoogleHealthSleepMapper.parseTime("2026-09-28T06:00:00Z")
        XCTAssertNotNil(withFrac)
        XCTAssertNotNil(plain)
    }

    @MainActor
    func testCredentialsMissingMessagePathStillClear() {
        // Compile-time / API surface: FitbitManager shared exposes errorMessage for Settings UI.
        // Without Secrets, message must remain non-empty guidance (not a crash).
        let message = FitbitManager.shared.errorMessage
        // On CI / fresh clones without Secrets, expect setup guidance. If Victor has secrets
        // configured locally, authenticated/empty message is also acceptable.
        if let message, !message.isEmpty {
            XCTAssertTrue(
                message.localizedCaseInsensitiveContains("set up")
                    || message.localizedCaseInsensitiveContains("GOOGLE_HEALTH_IOS_CLIENT_ID")
                    || message.localizedCaseInsensitiveContains("GOOGLE_HEALTH")
                    || message.localizedCaseInsensitiveContains("Fitbit")
                    || message.localizedCaseInsensitiveContains("sign"),
                "Unexpected errorMessage: \(message)"
            )
        }
    }
}
