import SwiftUI

// MARK: - Poincaré Plot for HRV Analysis
// Shows RR interval n vs n+1 scatter plot
struct PoincarePlotView: View {
    let rrIntervals: [Double] // in milliseconds
    let size: CGFloat
    
    private var points: [(x: Double, y: Double)] {
        guard rrIntervals.count >= 2 else { return [] }
        return (0..<rrIntervals.count - 1).map { i in
            (x: rrIntervals[i], y: rrIntervals[i + 1])
        }
    }
    
    private var sd1: Double {
        // Short-term variability (perpendicular to line of identity)
        let diffs = points.map { $0.y - $0.x }
        let mean = diffs.reduce(0, +) / Double(diffs.count)
        let variance = diffs.map { pow($0 - mean, 2) }.reduce(0, +) / Double(diffs.count)
        return sqrt(variance / 2)
    }
    
    private var sd2: Double {
        // Long-term variability (along line of identity)
        let sums = points.map { $0.y + $0.x }
        let mean = sums.reduce(0, +) / Double(sums.count)
        let variance = sums.map { pow($0 - mean, 2) }.reduce(0, +) / Double(sums.count)
        return sqrt(variance / 2)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Plot
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height
                let padding: CGFloat = 20
                
                let plotWidth = width - padding * 2
                let plotHeight = height - padding * 2
                
                let allValues = rrIntervals
                let minVal = allValues.min() ?? 0
                let maxVal = allValues.max() ?? 1
                let range = maxVal - minVal
                
                ZStack {
                    // Background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RTColor.surface)
                    
                    // Grid lines
                    ForEach(0..<5) { i in
                        let pos = CGFloat(i) / 4.0
                        
                        // Horizontal
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 0.5)
                            .position(
                                x: width / 2,
                                y: padding + plotHeight * (1 - pos)
                            )
                        
                        // Vertical
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 0.5)
                            .position(
                                x: padding + plotWidth * pos,
                                y: height / 2
                            )
                    }
                    
                    // Line of identity (y = x)
                    LineOfIdentity(
                        from: CGPoint(
                            x: padding + plotWidth * CGFloat((minVal - minVal) / range),
                            y: padding + plotHeight * CGFloat(1 - (minVal - minVal) / range)
                        ),
                        to: CGPoint(
                            x: padding + plotWidth * CGFloat((maxVal - minVal) / range),
                            y: padding + plotHeight * CGFloat(1 - (maxVal - minVal) / range)
                        )
                    )
                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    
                    // SD1 ellipse (perpendicular to line of identity)
                    if points.count >= 10 {
                        Ellipse()
                            .stroke(RTColor.hrv.opacity(0.4), lineWidth: 1.5)
                            .frame(
                                width: plotWidth * CGFloat(sd1 / range) * 2,
                                height: plotHeight * CGFloat(sd1 / range) * 2
                            )
                            .position(x: width / 2, y: height / 2)
                            .rotationEffect(.degrees(45))
                    }
                    
                    // Data points
                    ForEach(0..<points.count, id: \.self) { i in
                        let point = points[i]
                        let x = padding + plotWidth * CGFloat((point.x - minVal) / range)
                        let y = padding + plotHeight * CGFloat(1 - (point.y - minVal) / range)
                        
                        Circle()
                            .fill(RTColor.hrv.opacity(0.7))
                            .frame(width: 4, height: 4)
                            .position(x: x, y: y)
                    }
                    
                    // Axes labels
                    VStack {
                        Text("RR(n+1) (ms)")
                            .font(.caption2)
                            .foregroundColor(RTColor.tertiaryText)
                        Spacer()
                    }
                    .frame(width: width, height: height)
                    .padding(.top, 4)
                    
                    HStack {
                        Spacer()
                        Text("RR(n) (ms)")
                            .font(.caption2)
                            .foregroundColor(RTColor.tertiaryText)
                    }
                    .frame(width: width, height: height)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }
            }
            .frame(height: size)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Poincaré plot")
            .accessibilityValue("Scatter plot of each RR interval against the next, \(points.count) points. SD1 \(String(format: "%.1f", sd1)) milliseconds, SD2 \(String(format: "%.1f", sd2)) milliseconds")
            
            // Stats
            HStack(spacing: 20) {
                StatBadge(label: "SD1", value: String(format: "%.1f", sd1), unit: "ms", color: RTColor.hrv)
                StatBadge(label: "SD2", value: String(format: "%.1f", sd2), unit: "ms", color: RTColor.sleep)
                StatBadge(label: "SD1/SD2", value: String(format: "%.2f", sd1 / max(sd2, 0.001)), unit: "", color: RTColor.optimal)
            }
        }
    }
}

struct LineOfIdentity: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(RTColor.secondaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(RTColor.tertiaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RTColor.surface)
        )
        .accessibilityElement(children: .combine)
    }
}
