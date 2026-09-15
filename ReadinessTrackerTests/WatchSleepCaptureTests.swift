import XCTest
import SwiftUI
import UIKit
@testable import Readiness

/// Optional ImageRenderer capture for `.audit/verify-watch-sleep.png`.
/// `Scripts/capture-watch-sleep.sh` drops a sentinel at `/tmp/rt-audit/CAPTURE_WATCH_SLEEP`.
final class WatchSleepCaptureTests: XCTestCase {
    private static let sentinelPath = "/tmp/rt-audit/CAPTURE_WATCH_SLEEP"
    private static let defaultPNGPath = "/tmp/rt-audit/verify-watch-sleep.png"

    @MainActor
    func testCaptureWatchSleepPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelOK = FileManager.default.fileExists(atPath: Self.sentinelPath)
            || env["CAPTURE_WATCH_SLEEP"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(Self.sentinelPath) or set CAPTURE_WATCH_SLEEP=1 to render audit PNG")
        }

        let path = env["WATCH_SLEEP_PNG_PATH"] ?? Self.defaultPNGPath

        let view = WatchSleepChrome(
            sleepHours: 7.4,
            sleepEfficiency: 0.91,
            sleepScore: 80,
            deepSleepPercent: 0.18,
            remSleepPercent: 0.24
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
        attachment.name = "verify-watch-sleep.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
