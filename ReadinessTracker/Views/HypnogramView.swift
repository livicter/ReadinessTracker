import SwiftUI
import Charts

/// Real hypnogram: x = time, y = stage depth (Awake top, Deep bottom).
/// Renders RectangleMark per interval; tap-to-inspect tooltip and pinch zoom
/// when `interactive` is true.
struct HypnogramView: View {
    let intervals: [SleepStageInterval]
    var interactive: Bool = true

    @State private var selected: SleepStageInterval?
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    /// Last time a pinch was active; suppresses the drag-as-tap that ends with it.
    @State private var lastPinchTime: Date = .distantPast

    private var sorted: [SleepStageInterval] {
        intervals.sorted { $0.startDate < $1.startDate }
    }

    private var fullRange: ClosedRange<Date>? {
        guard let first = sorted.first, let last = sorted.last else { return nil }
        return first.startDate...last.endDate
    }

    /// Centered zoom: shrink the visible window around the midpoint.
    private var visibleDomain: ClosedRange<Date>? {
        guard let full = fullRange else { return nil }
        let total = full.upperBound.timeIntervalSince(full.lowerBound)
        let visible = total / Double(max(zoomScale, 1))
        let mid = full.lowerBound.addingTimeInterval(total / 2)
        return mid.addingTimeInterval(-visible / 2)...mid.addingTimeInterval(visible / 2)
    }

    var body: some View {
        if sorted.isEmpty {
            // Deployment target is iOS 16, so no ContentUnavailableView (iOS 17+).
            Text("No detailed stage data. Stage intervals are recorded from your next sync.")
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
                .frame(height: 160)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                chart

                if interactive, let selected {
                    tooltip(for: selected)
                }

                if interactive {
                    timeLabels
                }
            }
        }
    }

    private var chart: some View {
        // Enumerated offset as id: startDate ids collide when intervals share a start.
        Chart(Array(sorted.enumerated()), id: \.offset) { pair in
            let interval = pair.element
            RectangleMark(
                xStart: .value("Start", interval.startDate),
                xEnd: .value("End", interval.endDate),
                yStart: .value("Top", interval.stage.depthRank - 1),
                yEnd: .value("Bottom", interval.stage.depthRank)
            )
            .foregroundStyle(interval.stage.color)
            .opacity(selected == nil || selected == interval ? 1.0 : 0.4)
        }
        .chartYScale(domain: -4...0)
        .chartYAxis {
            AxisMarks(position: .leading, values: [-1, -2, -3, -4]) { value in
                AxisValueLabel {
                    if let rank = value.as(Int.self) {
                        Text(rankLabel(for: rank))
                            .font(.caption2)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                }
            }
        }
        .chartXScale(domain: visibleDomain ?? Date()...Date())
        .chartXAxis {
            AxisMarks { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.05))
                AxisValueLabel(format: .dateTime.hour().minute())
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .frame(height: interactive ? 180 : 100)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(interactive ? tapGesture(proxy: proxy, geo: geo) : nil)
                    // simultaneousGesture so DragGesture(minimumDistance: 0),
                    // which recognizes on touch down, cannot preempt the pinch
                    .simultaneousGesture(interactive ? zoomGesture : nil)
            }
        }
    }

    // DragGesture(minimumDistance: 0) doubles as a located tap on iOS 16
    // (SpatialTapGesture is iOS 17+). plotFrame is iOS 17+, so on iOS 16 we
    // fall back to manual mapping against the known x domain.
    // ponytail: manual mapping spans the full overlay width (y-axis labels
    // included), so taps land slightly left of the true interval — acceptable
    // for a legacy-OS fallback; upgrade path is SpatialTapGesture + plotFrame
    // once the deployment target hits iOS 17.
    private func tapGesture(proxy: ChartProxy, geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onEnded { event in
                // A lift-off right after a pinch is not a tap.
                guard Date().timeIntervalSince(lastPinchTime) > 0.35 else { return }
                let date: Date?
                if #available(iOS 17.0, *), let plotFrame = proxy.plotFrame {
                    let x = event.location.x - geo[plotFrame].origin.x
                    date = proxy.value(atX: x)
                } else {
                    date = manualDate(atX: event.location.x, width: geo.size.width)
                }
                guard let date, let match = sorted.first(where: { date >= $0.startDate && date < $0.endDate }) else { return }
                selected = match
                Haptic.selectionChanged()
            }
    }

    /// iOS 16 fallback: map an x position to a date via the visible domain.
    private func manualDate(atX x: CGFloat, width: CGFloat) -> Date? {
        guard let domain = visibleDomain, width > 0 else { return nil }
        let fraction = min(max(x / width, 0), 1)
        let span = domain.upperBound.timeIntervalSince(domain.lowerBound)
        return domain.lowerBound.addingTimeInterval(span * Double(fraction))
    }

    // MagnificationGesture is the iOS 16 spelling of MagnifyGesture.
    // Its value resets each gesture, so multiply onto the persisted scale.
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                lastPinchTime = Date()
                zoomScale = min(max(lastZoomScale * value, 1), 8)
            }
            .onEnded { value in
                lastZoomScale = min(max(lastZoomScale * value, 1), 8)
            }
    }

    private func tooltip(for interval: SleepStageInterval) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(interval.stage.color)
                .frame(width: 10, height: 10)
            Text(interval.stage.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text("\(interval.startDate, format: .dateTime.hour().minute()) – \(interval.endDate, format: .dateTime.hour().minute())")
                .font(.caption)
                .foregroundStyle(RTColor.secondaryText)
            Spacer()
            Text("\(Int(interval.durationMinutes)) min")
                .font(.caption.weight(.semibold))
                .foregroundStyle(interval.stage.color)
        }
        .padding(10)
        .background(RTColor.surfaceHighlight)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var timeLabels: some View {
        HStack {
            if let range = visibleDomain {
                Text(range.lowerBound, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text(range.upperBound, format: .dateTime.hour().minute())
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
    }

    private func rankLabel(for rank: Int) -> String {
        // depthRank - 1 = y value; map back to stage name
        switch rank {
        case -1: return "Awake"
        case -2: return "REM"
        case -3: return "Light"
        default: return "Deep"
        }
    }
}
