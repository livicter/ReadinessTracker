import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Snapshot-safe Fitness-style Gym / Work / Sleep rings (Home + Lock Screen widget + Watch + audit render).
/// No animation — suitable for WidgetKit timelines, watchOS glance, and `ImageRenderer` PNG capture.
struct CompactTripleRingsView: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    let size: CGFloat
    var showsCaption: Bool = true
    var minimumLineWidth: CGFloat = 5
    var gap: CGFloat = 2

    var gymColor: Color = Color(red: 255/255, green: 59/255, blue: 48/255)
    var workColor: Color = Color(red: 52/255, green: 199/255, blue: 89/255)
    var sleepColor: Color = Color(red: 88/255, green: 86/255, blue: 214/255)
    var valueColor: Color = .primary
    var captionColor: Color = .secondary

    private var layout: TripleRingGeometry.Layout {
        TripleRingGeometry.layout(size: size, minimumLineWidth: minimumLineWidth, gap: gap)
    }

    var body: some View {
        let layout = self.layout
        let overall = TripleRingGeometry.overallScore(gym: gymScore, work: workScore, sleep: sleepScore)
        ZStack {
            staticRing(
                progress: TripleRingGeometry.progress(score: sleepScore),
                color: sleepColor,
                lineWidth: layout.lineWidth,
                size: layout.outerSize
            )
            staticRing(
                progress: TripleRingGeometry.progress(score: workScore),
                color: workColor,
                lineWidth: layout.lineWidth,
                size: layout.middleSize
            )
            staticRing(
                progress: TripleRingGeometry.progress(score: gymScore),
                color: gymColor,
                lineWidth: layout.lineWidth,
                size: layout.innerSize
            )
            VStack(spacing: 1) {
                Text("\(overall)")
                    .font(.system(size: layout.scoreFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                if showsCaption {
                    Text("READY")
                        .font(.system(size: layout.captionFontSize, weight: .semibold))
                        .foregroundStyle(captionColor)
                        .tracking(1.2)
                }
            }
            .frame(width: layout.holeDiameter * 0.85)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Readiness")
        .accessibilityValue("\(overall). Gym \(gymScore), Work \(workScore), Sleep \(sleepScore)")
    }

    private func staticRing(progress: CGFloat, color: Color, lineWidth: CGFloat, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

#if os(iOS)
/// Small Home Screen widget chrome used for audit PNG (`verify-home-widget.png`).
struct HomeWidgetSmallChrome: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int

    var body: some View {
        VStack(spacing: 6) {
            CompactTripleRingsView(
                gymScore: gymScore,
                workScore: workScore,
                sleepScore: sleepScore,
                size: 96
            )
            Text("Readiness")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
        }
        .padding(12)
        .frame(width: 158, height: 158)
        .background(Color(uiColor: .systemBackground))
    }
}

/// Watch dashboard hero chrome used for audit PNG (`verify-watch-dashboard.png`).
/// Mirrors watchOS glance sizing on a black canvas (ImageRenderer runs in iOS unit tests).
struct WatchDashboardChrome: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int

    var body: some View {
        VStack(spacing: 8) {
            CompactTripleRingsView(
                gymScore: gymScore,
                workScore: workScore,
                sleepScore: sleepScore,
                size: 110,
                minimumLineWidth: 5,
                gap: 2,
                valueColor: .white,
                captionColor: Color.white.opacity(0.55)
            )
            Text("Readiness")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(16)
        .frame(width: 184, height: 224)
        .background(Color.black)
    }
}

/// Lock Screen `accessoryCircular` chrome used for audit PNG (`verify-lock-widget.png`).
/// Dark circular slot mirrors Lock Screen; rings reuse `CompactTripleRingsView` at accessory scale.
struct LockScreenAccessoryChrome: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
            CompactTripleRingsView(
                gymScore: gymScore,
                workScore: workScore,
                sleepScore: sleepScore,
                size: 72,
                showsCaption: false,
                minimumLineWidth: 3.5,
                gap: 1.5,
                valueColor: .white,
                captionColor: Color.white.opacity(0.55)
            )
        }
        .frame(width: 100, height: 100)
        .background(Color(white: 0.12))
    }
}

#endif
