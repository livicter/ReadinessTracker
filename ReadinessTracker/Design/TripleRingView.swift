import SwiftUI

// MARK: - Triple Ring Hero (Apple Watch Activity-style)
struct TripleRingHero: View {
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Outer glow effect
            Circle()
                .stroke(RTColor.divider, lineWidth: 1)
                .frame(width: size + 20, height: size + 20)
            
            // Sleep ring (outermost)
            ActivityRing(
                progress: Double(sleepScore) / 100,
                color: RTColor.sleep,
                lineWidth: 14,
                size: size
            )
            
            // Work ring (middle)
            ActivityRing(
                progress: Double(workScore) / 100,
                color: RTColor.hrv,
                lineWidth: 14,
                size: size * 0.72
            )
            
            // Gym ring (innermost)
            ActivityRing(
                progress: Double(gymScore) / 100,
                color: RTColor.strain,
                lineWidth: 14,
                size: size * 0.44
            )
            
            // Center score display
            VStack(spacing: 2) {
                // Fixed size by design — lives inside a fixed-size ring; Dynamic Type would break the layout
                Text("\(overallScore)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(RTColor.primaryText)
                
                Text("READY")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(RTColor.secondaryText)
                    .tracking(2)
            }
        }
        .frame(width: size + 20, height: size + 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Readiness score")
        .accessibilityValue("\(overallScore) out of 100. Sleep \(sleepScore), work \(workScore), gym \(gymScore)")
        .accessibilityAddTraits(.isSummaryElement)
    }
    
    private var overallScore: Int {
        Int((Double(gymScore) + Double(workScore) + Double(sleepScore)) / 3.0)
    }
}

// MARK: - Activity Ring (Apple Watch style)
struct ActivityRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            
            // Progress ring with gradient
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Glow at the tip
            if animatedProgress > 0.05 {
                Circle()
                    .fill(color)
                    .frame(width: lineWidth * 0.8, height: lineWidth * 0.8)
                    .offset(
                        x: cos((min(animatedProgress, 1.0) * 360 - 90) * .pi / 180) * (size / 2 - lineWidth / 2),
                        y: sin((min(animatedProgress, 1.0) * 360 - 90) * .pi / 180) * (size / 2 - lineWidth / 2)
                    )
                    .shadow(color: color, radius: 6)
            }
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

// MARK: - Ring Legend
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
