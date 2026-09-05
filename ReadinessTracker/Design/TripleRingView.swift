import SwiftUI

struct TripleRingHero: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    let size: CGFloat

    private let lineWidth: CGFloat = 14
    private let gap: CGFloat = 4

    var body: some View {
        let middle = size - 2 * (lineWidth + gap)
        let inner = size - 4 * (lineWidth + gap)
        ZStack {
            ActivityRing(
                progress: Double(sleepScore) / 100,
                color: RTColor.sleep,
                lineWidth: lineWidth,
                size: size
            )
            ActivityRing(
                progress: Double(workScore) / 100,
                color: RTColor.hrv,
                lineWidth: lineWidth,
                size: middle
            )
            ActivityRing(
                progress: Double(gymScore) / 100,
                color: RTColor.strain,
                lineWidth: lineWidth,
                size: inner
            )
            VStack(spacing: 2) {
                Text("\(overallScore)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(RTColor.primaryText)
                Text("READY")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(RTColor.secondaryText)
                    .tracking(2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Readiness score")
        .accessibilityValue("\(overallScore) out of 100. Sleep \(sleepScore), work \(workScore), gym \(gymScore)")
        .accessibilityAddTraits(.isSummaryElement)
        .accessibilityIdentifier("today.rings")
    }

    private var overallScore: Int {
        Int((Double(gymScore) + Double(workScore) + Double(sleepScore)) / 3.0)
    }
}

struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress ring")
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent")
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newValue in
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = newValue
            }
        }
    }
}

struct RingLegend: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int

    var body: some View {
        HStack(spacing: 20) {
            LegendItem(label: "Gym", score: gymScore, color: RTColor.strain, icon: "dumbbell.fill")
            LegendItem(label: "Work", score: workScore, color: RTColor.hrv, icon: "brain.head.profile")
            LegendItem(label: "Sleep", score: sleepScore, color: RTColor.sleep, icon: "bed.double.fill")
        }
    }
}

struct LegendItem: View {
    let label: String
    let score: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundColor(RTColor.secondaryText)
            }
            Text("\(score)")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(RTColor.primaryText)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) score \(score)")
    }
}
