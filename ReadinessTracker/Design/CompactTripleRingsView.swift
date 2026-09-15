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


/// Large Home Screen widget chrome used for audit PNG (`verify-home-widget-large.png`).
/// Mirrors `LargeWidgetView`: CompactTripleRingsView + Gym/Work/Sleep rows + HRV/RHR/Sleep hours.
struct HomeWidgetLargeChrome: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    var readinessScore: Int = 78
    var hrv: Int = 45
    var rhr: Int = 58
    var sleepHours: Double = 7.5

    private let gymColor = Color(red: 255/255, green: 59/255, blue: 48/255)
    private let workColor = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let sleepColor = Color(red: 88/255, green: 86/255, blue: 214/255)
    private let track = Color.primary.opacity(0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                CompactTripleRingsView(
                    gymScore: gymScore,
                    workScore: workScore,
                    sleepScore: sleepScore,
                    size: 120
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Readiness")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text("\(readinessScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .monospacedDigit()
                    Text("Gym · Work · Sleep")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    chromeCheckInControl()
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                chromeScoreRow(label: "Gym", score: gymScore, color: gymColor)
                chromeScoreRow(label: "Work", score: workScore, color: workColor)
                chromeScoreRow(label: "Sleep", score: sleepScore, color: sleepColor)
            }

            Divider()

            HStack(spacing: 16) {
                chromeMetricMini(label: "HRV", value: "\(hrv)", unit: "ms")
                chromeMetricMini(label: "RHR", value: "\(rhr)", unit: "bpm")
                chromeMetricMini(label: "Sleep", value: String(format: "%.1f", sleepHours), unit: "h")
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(width: 338, height: 354, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
    }

    private func chromeCheckInControl(compact: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
            Text("Check-in")
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color(red: 52/255, green: 199/255, blue: 89/255))
        )
        .accessibilityLabel("Open Check-in")
    }

    private func chromeScoreRow(label: String, score: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
                .frame(width: 40, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(track)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                }
            }
            .frame(height: 6)
            Text("\(score)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func chromeMetricMini(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}

/// Medium + large Home widget chrome with Fitness-style deep-link controls
/// (Check-in / Evening / Trends — `verify-home-widget-deeplinks.png`).
/// Mirrors interactive Links on real widgets.
struct HomeWidgetCheckInChrome: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    var readinessScore: Int = 78
    var hrv: Int = 45
    var rhr: Int = 58
    var sleepHours: Double = 7.5

    private let gymColor = Color(red: 255/255, green: 59/255, blue: 48/255)
    private let workColor = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let sleepColor = Color(red: 88/255, green: 86/255, blue: 214/255)
    private let track = Color.primary.opacity(0.08)
    private let checkInGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let eveningIndigo = Color(red: 88/255, green: 86/255, blue: 214/255)
    private let trendsBlue = Color(red: 0/255, green: 122/255, blue: 255/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            mediumCard
            largeCard
        }
        .padding(12)
        .frame(width: 360, alignment: .topLeading)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var mediumCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                CompactTripleRingsView(
                    gymScore: gymScore,
                    workScore: workScore,
                    sleepScore: sleepScore,
                    size: 100
                )
                Text("Readiness")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                scoreRow(label: "Gym", score: gymScore, color: gymColor)
                scoreRow(label: "Work", score: workScore, color: workColor)
                scoreRow(label: "Sleep", score: sleepScore, color: sleepColor)
                Divider()
                HStack(spacing: 8) {
                    metricMini(label: "HRV", value: "\(hrv)", unit: "ms")
                    metricMini(label: "RHR", value: "\(rhr)", unit: "bpm")
                    Spacer(minLength: 0)
                    trendsPill(compact: true)
                    checkInPill(compact: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(width: 338, height: 158)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var largeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                CompactTripleRingsView(
                    gymScore: gymScore,
                    workScore: workScore,
                    sleepScore: sleepScore,
                    size: 120
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Readiness")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                    Text("\(readinessScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .monospacedDigit()
                    Text("Gym · Work · Sleep")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.secondary)
                    HStack(spacing: 6) {
                        checkInPill()
                        eveningPill()
                    }
                    .padding(.top, 4)
                    trendsPill()
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 10) {
                scoreRow(label: "Gym", score: gymScore, color: gymColor)
                scoreRow(label: "Work", score: workScore, color: workColor)
                scoreRow(label: "Sleep", score: sleepScore, color: sleepColor)
            }
            Divider()
            HStack(spacing: 16) {
                metricMini(label: "HRV", value: "\(hrv)", unit: "ms")
                metricMini(label: "RHR", value: "\(rhr)", unit: "bpm")
                metricMini(label: "Sleep", value: String(format: "%.1f", sleepHours), unit: "h")
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(width: 338, height: 354, alignment: .topLeading)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func checkInPill(compact: Bool = false) -> some View {
        actionPill(
            icon: "checkmark.circle.fill",
            title: "Check-in",
            color: checkInGreen,
            compact: compact,
            accessibility: "Open Check-in"
        )
    }

    private func eveningPill(compact: Bool = false) -> some View {
        actionPill(
            icon: "moon.stars.fill",
            title: "Evening",
            color: eveningIndigo,
            compact: compact,
            accessibility: "Open Evening Check-in"
        )
    }

    private func trendsPill(compact: Bool = false) -> some View {
        actionPill(
            icon: "chart.line.uptrend.xyaxis",
            title: "Trends",
            color: trendsBlue,
            compact: compact,
            accessibility: "Open Trends"
        )
    }

    private func actionPill(
        icon: String,
        title: String,
        color: Color,
        compact: Bool,
        accessibility: String
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
            Text(title)
                .font(.system(size: compact ? 11 : 12, weight: .semibold))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(Capsule(style: .continuous).fill(color))
        .accessibilityLabel(accessibility)
    }

    private func scoreRow(label: String, score: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.secondary)
                .frame(width: 40, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(track)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                }
            }
            .frame(height: 6)
            Text("\(score)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)
        }
    }

    private func metricMini(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
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


/// Lock Screen `accessoryRectangular` chrome used for audit PNG (`verify-lock-widget-rectangular.png`).
/// Dark rounded slot mirrors Lock Screen; rings reuse `CompactTripleRingsView` at accessory height.
struct LockScreenRectangularChrome: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    var readinessScore: Int = 78

    var body: some View {
        HStack(spacing: 10) {
            CompactTripleRingsView(
                gymScore: gymScore,
                workScore: workScore,
                sleepScore: sleepScore,
                size: 56,
                showsCaption: false,
                minimumLineWidth: 3,
                gap: 1.5,
                valueColor: .white,
                captionColor: Color.white.opacity(0.55)
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("Readiness")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.55))
                Text("\(readinessScore)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                HStack(spacing: 6) {
                    Text("G\(gymScore)")
                        .foregroundStyle(Color(red: 255/255, green: 59/255, blue: 48/255))
                    Text("W\(workScore)")
                        .foregroundStyle(Color(red: 52/255, green: 199/255, blue: 89/255))
                    Text("S\(sleepScore)")
                        .foregroundStyle(Color(red: 88/255, green: 86/255, blue: 214/255))
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 172, height: 72)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(8)
        .background(Color(white: 0.12))
    }
}

#endif
