import XCTest
import SwiftUI
import UIKit
@testable import Readiness

/// Optional ImageRenderer capture for `.audit/verify-home-widget.png`.
/// `Scripts/capture-home-widget.sh` drops a sentinel at `/tmp/rt-audit/CAPTURE_HOME_WIDGET`.
final class HomeWidgetCaptureTests: XCTestCase {
    private static let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET"
    private static let defaultPNGPath = "/tmp/rt-audit/verify-home-widget.png"

    @MainActor
    func testCaptureHomeWidgetPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelOK = FileManager.default.fileExists(atPath: Self.sentinelPath)
            || env["CAPTURE_HOME_WIDGET"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(Self.sentinelPath) or set CAPTURE_HOME_WIDGET=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_PNG_PATH"] ?? Self.defaultPNGPath

        let view = HomeWidgetSmallChrome(
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            lastUpdate: Date().addingTimeInterval(-5 * 60)
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
        attachment.name = "verify-home-widget.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureHomeWidgetLargePNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET_LARGE"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_HOME_WIDGET_LARGE"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_HOME_WIDGET_LARGE=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_LARGE_PNG_PATH"] ?? "/tmp/rt-audit/verify-home-widget-large.png"

        let view = HomeWidgetLargeChrome(gymScore: 82, workScore: 75, sleepScore: 80)
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
        attachment.name = "verify-home-widget-large.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }


    @MainActor
    func testCaptureHomeWidgetExtraLargePNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET_EXTRA_LARGE"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_HOME_WIDGET_EXTRA_LARGE"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_HOME_WIDGET_EXTRA_LARGE=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_EXTRA_LARGE_PNG_PATH"] ?? "/tmp/rt-audit/verify-home-widget-extra-large.png"

        let view = HomeWidgetExtraLargeChrome(gymScore: 82, workScore: 75, sleepScore: 80)
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
        attachment.name = "verify-home-widget-extra-large.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureHomeWidgetUpdatedPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET_UPDATED"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_HOME_WIDGET_UPDATED"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_HOME_WIDGET_UPDATED=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_UPDATED_PNG_PATH"] ?? "/tmp/rt-audit/verify-home-widget-updated.png"

        let view = HomeWidgetUpdatedChrome(
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            lastUpdate: Date().addingTimeInterval(-5 * 60)
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
        attachment.name = "verify-home-widget-updated.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor
    func testCaptureHomeWidgetLiveUpdatedPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET_LIVE_UPDATED"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_HOME_WIDGET_LIVE_UPDATED"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_HOME_WIDGET_LIVE_UPDATED=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_LIVE_UPDATED_PNG_PATH"] ?? "/tmp/rt-audit/verify-home-widget-live-updated.png"

        let view = HomeWidgetUpdatedChrome(
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            lastUpdate: Date().addingTimeInterval(-5 * 60)
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
        attachment.name = "verify-home-widget-live-updated.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCaptureHomeWidgetSmallUpdatedPNGWhenRequested() throws {
        let env = ProcessInfo.processInfo.environment
        let sentinelPath = "/tmp/rt-audit/CAPTURE_HOME_WIDGET_SMALL_UPDATED"
        let sentinelOK = FileManager.default.fileExists(atPath: sentinelPath)
            || env["CAPTURE_HOME_WIDGET_SMALL_UPDATED"] == "1"
        guard sentinelOK else {
            throw XCTSkip("Drop \(sentinelPath) or set CAPTURE_HOME_WIDGET_SMALL_UPDATED=1 to render audit PNG")
        }

        let path = env["HOME_WIDGET_SMALL_UPDATED_PNG_PATH"] ?? "/tmp/rt-audit/verify-home-widget-small-updated.png"

        let view = HomeWidgetSmallChrome(
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            lastUpdate: Date().addingTimeInterval(-5 * 60)
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
        attachment.name = "verify-home-widget-small-updated.png"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
