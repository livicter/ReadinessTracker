import XCTest
import SwiftUI
import UIKit
@testable import Readiness

/// Optional ImageRenderer capture for `.audit/verify-watch-checkin.png`.
/// `Scripts/capture-watch-checkin.sh` drops a sentinel at `/tmp/rt-audit/CAPTURE_WATCH_CHECKIN`.
final class WatchCheckInCaptureTests: XCTestCase {
    private static let sentinelPath = "/tmp/rt-audit/CAPTURE_WATCH_CHECKIN"
    private static let defaultPNGPath = "/tmp/rt-audit/verify-watch-checkin.png"

    @MainActor
    func testCaptureWatchCheckInPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelOK = FileManager.default.fileExists(atPath: Self.sentinelPath)
            || env["CAPTURE_WATCH_CHECKIN"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(Self.sentinelPath) or set CAPTURE_WATCH_CHECKIN=1 to render audit PNG")
        }

        let path = env["WATCH_CHECKIN_PNG_PATH"] ?? Self.defaultPNGPath

        let view = WatchCheckInChrome(
            timeOfDay: "Evening",
            feel: 4,
            alcohol: false,
            lateCaffeine: true,
            sick: false,
            workoutToday: true
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        guard let image = renderer.uiImage, let data = image.pngData() else {
            XCTFail("ImageRenderer failed")
            return
        }
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url)
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), path)
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let size = attrs[.size] as? NSNumber
        XCTAssertGreaterThan(size?.intValue ?? 0, 1000)

        let attachment = XCTAttachment(image: image)
        attachment.name = "verify-watch-checkin.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
