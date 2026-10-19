import SwiftUI
import Charts

/// Honest #498: Fitbit / Google Health air-data density card.
/// Live field chips with values, density ring, and 7-day steps spark.
/// Visible for every source; Fitbit branding + Google Health caption when selected.
struct FitbitAirDataCard: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    let source: DataSource

    @State private var selectedChipID: String?
    /// Honest #503: interactive spark window.
    @State private var sparkPeriod: Int = 7
    /// Honest #505: which air field the spark charts.
    @State private var sparkMetric: AirSparkMetric = .steps
    /// Honest #507: interactive spark scrub index.
    @State private var sparkScrubIndex: Int? = nil
    /// Honest #509: which air gap pill is expanded.
    @State private var focusedGapID: String? = nil
    /// Honest #513: density legend category focus (Sleep / Vitals / Activity).
    @State private var focusedLegend: AirDensityCategory? = nil

    private let accent = Color(hex: "00B0B9")  // Fitbit teal

    private var chips: [AirChip] {
        AirChip.all(from: data)
    }

    private var filledCount: Int { chips.filter(\.filled).count }
    private var density: Double {
        guard !chips.isEmpty else { return 0 }
        return Double(filledCount) / Double(chips.count)
    }

    private var sparkPoints: [(date: Date, value: Double)] {
        history.suffix(sparkPeriod).map { day in
            (date: day.date, value: sparkMetric.value(from: day))
        }
    }

    private var selectedChip: AirChip? {
        chips.first { $0.id == selectedChipID }
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                header
                // Honest #506: classic MetricDetail entry near top so it stays hittable with card title.
                chipMetricDetailLink
                HStack(alignment: .center, spacing: 16) {
                    densityRing
                    chipGrid
                }
                densityLegend
                densityHistorySpark
                if let selectedChip {
                    selectedDetail(selectedChip)
                }
                airGapsStrip
                if sparkPoints.contains(where: { $0.value > 0 }) {
                    sparkBlock
                }
            }
            .padding(16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.fitbitAirDataCard)
        .accessibilityLabel(source == .fitbit ? "Fitbit air data" : "Health air data")
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(source == .fitbit ? "Fitbit Air" : "Health Air")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(source == .fitbit
                     ? "Google Health fields live tonight"
                     : "Tonight’s field density · switch to Fitbit for GH sync")
                    .font(.subheadline)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer()
            Text("\(filledCount)/\(chips.count)")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accent.opacity(0.12))
                .clipShape(Capsule())
                .accessibilityIdentifier(SurfaceID.fitbitAirDataDensity)
        }
    }

    private var densityRing: some View {
        ZStack {
            Circle()
                .stroke(RTColor.divider, lineWidth: 8)
            // Honest #513: category arcs (Sleep / Vitals / Activity) + overall trim
            ForEach(Array(AirDensityCategory.allCases.enumerated()), id: \.element.id) { idx, cat in
                densityCategoryArc(cat, index: idx)
            }
            Circle()
                .trim(from: 0, to: CGFloat(density))
                .stroke(accent.opacity(focusedLegend == nil ? 0.35 : 0.12),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: density)
            VStack(spacing: 2) {
                Text("\(Int((density * 100).rounded()))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
                Text(focusedLegend?.shortTitle ?? "AIR")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(focusedLegend?.color ?? RTColor.secondaryText)
            }
        }
        .frame(width: 84, height: 84)
        .animation(.easeInOut(duration: 0.25), value: focusedLegend)
        .accessibilityLabel("Air density \(Int((density * 100).rounded())) percent")
    }


    private func densityCategoryArc(_ cat: AirDensityCategory, index: Int) -> some View {
        let span = 1.0 / Double(AirDensityCategory.allCases.count)
        let start = Double(index) * span
        let end = start + span * cat.fillRatio(in: chips)
        let dimmed = focusedLegend != nil && focusedLegend != cat
        return Circle()
            .trim(from: CGFloat(start), to: CGFloat(max(start, end)))
            .stroke(cat.color.opacity(dimmed ? 0.25 : 0.95),
                    style: StrokeStyle(lineWidth: focusedLegend == cat ? 10 : 8, lineCap: .round))
            .rotationEffect(.degrees(-90))
    }


    private func densityLegendPill(_ cat: AirDensityCategory) -> some View {
        let filled = cat.filledCount(in: chips)
        let total = cat.chipIDs.count
        return Button {
            Haptic.selectionChanged()
            focusedLegend = focusedLegend == cat ? nil : cat
            if let focus = focusedLegend {
                let ids = focus.chipIDs
                selectedChipID = chips.first(where: { ids.contains($0.id) && $0.filled })?.id
                    ?? chips.first(where: { ids.contains($0.id) })?.id
                // Honest #517: legend → spark metric link
                sparkMetric = focus.sparkMetric
                sparkScrubIndex = nil
            }
        } label: {
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 7, height: 7)
                    Text(cat.title)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(focusedLegend == cat ? Color.white : RTColor.primaryText)
                }
                Text("\(filled)/\(total)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(focusedLegend == cat ? Color.white.opacity(0.9) : cat.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(focusedLegend == cat ? cat.color : cat.color.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(focusedLegend == cat ? cat.color.opacity(0.8) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("fitbit.air.legend.\(cat.rawValue)")
        .accessibilityLabel("\(cat.title) density \(filled) of \(total)")
    }

    /// Honest #513: interactive Sleep / Vitals / Activity density legend.
    private var densityLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(AirDensityCategory.allCases) { cat in
                    densityLegendPill(cat)
                }
            }
            if let focusedLegend {
                HStack(spacing: 6) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.caption2)
                    Text("Spark → \(focusedLegend.sparkMetric.title)")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("linked")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(focusedLegend.color.opacity(0.15))
                        .clipShape(Capsule())
                }
                .foregroundStyle(focusedLegend.color)
                .accessibilityIdentifier(SurfaceID.fitbitAirLegendSparkLink)
                .accessibilityLabel("Spark linked to \(focusedLegend.sparkMetric.title)")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.fitbitAirDataDensityLegend)
        .accessibilityLabel("Air density legend")
    }

    /// Honest #514: history density% spark (same window as field spark).
    private var densityHistoryPoints: [(date: Date, density: Double)] {
        history.suffix(sparkPeriod).map { day in
            let dayChips = AirChip.all(from: day)
            let filled = dayChips.filter(\.filled).count
            let dens = dayChips.isEmpty ? 0.0 : Double(filled) / Double(dayChips.count)
            return (date: day.date, density: dens)
        }
    }

    private var densityHistorySpark: some View {
        let points = densityHistoryPoints
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Density · \(sparkPeriod)d")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if let idx = sparkScrubIndex ?? (points.isEmpty ? nil : points.count - 1),
                   points.indices.contains(idx) {
                    Text("\(Int((points[idx].density * 100).rounded()))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                }
            }
            if points.contains(where: { $0.density > 0 }) {
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { i, pt in
                        AreaMark(
                            x: .value("Day", pt.date),
                            y: .value("Density", pt.density)
                        )
                        .foregroundStyle(accent.opacity(0.18))
                        LineMark(
                            x: .value("Day", pt.date),
                            y: .value("Density", pt.density)
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                        if (sparkScrubIndex ?? points.count - 1) == i {
                            PointMark(
                                x: .value("Day", pt.date),
                                y: .value("Density", pt.density)
                            )
                            .foregroundStyle(accent)
                            .symbolSize(56)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...1)
                .frame(height: 44)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        sparkSelectDensity(at: value.location, proxy: proxy, geo: geo, count: points.count)
                                    }
                            )
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: sparkPeriod)
                .animation(.easeInOut(duration: 0.2), value: sparkScrubIndex)
            } else {
                Text("No density history in window")
                    .font(.caption)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .accessibilityIdentifier(SurfaceID.fitbitAirDataDensitySpark)
        .accessibilityLabel("Air density history spark")
    }

    private func sparkSelectDensity(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy, count: Int) {
        guard count >= 1 else { return }
        let width = max(geo.size.width, 1)
        let frac = min(max(location.x / width, 0), 1)
        let best = count == 1 ? 0 : min(count - 1, max(0, Int((frac * CGFloat(count - 1)).rounded())))
        _ = proxy
        if sparkScrubIndex != best {
            sparkScrubIndex = best
            Haptic.selectionChanged()
        }
    }

    private var chipGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 8)], spacing: 8) {
            ForEach(chips) { chip in
                Button {
                    Haptic.selectionChanged()
                    selectedChipID = selectedChipID == chip.id ? nil : chip.id
                } label: {
                    VStack(spacing: 4) {
                        Text(chip.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(chip.filled ? RTColor.primaryText : RTColor.secondaryText)
                            .lineLimit(1)
                        Text(chip.valueText)
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(chip.filled ? accent : RTColor.tertiaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .opacity(chipOpacity(chip))
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedChipID == chip.id
                                  ? accent.opacity(0.18)
                                  : (chip.filled ? accent.opacity(0.08) : RTColor.surfaceHighlight))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(selectedChipID == chip.id ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(chip.label) \(chip.valueText)")
            }
        }
        .accessibilityIdentifier(SurfaceID.fitbitAirDataChips)
    }



    private func chipOpacity(_ chip: AirChip) -> Double {
        guard let focus = focusedLegend else { return 1 }
        return focus.chipIDs.contains(chip.id) ? 1 : 0.35
    }

    /// Honest #509: empty Google Health / Fitbit air fields with fill guidance.
    private var gapChips: [AirChip] { chips.filter { !$0.filled } }

    private var airGapsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(gapChips.isEmpty ? "Air gaps" : "Air gaps · \(gapChips.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text(source == .fitbit ? "Google Health" : "HealthKit")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
            }
            if gapChips.isEmpty {
                Text("All air fields filled tonight")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(gapChips) { gap in
                            Button {
                                Haptic.selectionChanged()
                                focusedGapID = focusedGapID == gap.id ? nil : gap.id
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: gap.icon)
                                        .font(.caption2)
                                    Text(gap.label)
                                        .font(.caption.weight(.semibold))
                                }
                                .foregroundStyle(focusedGapID == gap.id ? Color.white : accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(focusedGapID == gap.id ? accent : accent.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Gap \(gap.label)")
                        }
                    }
                }
                Text(focusedGapHint)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier(SurfaceID.fitbitAirDataGaps)
        .accessibilityLabel("Air gaps")
    }

    private var focusedGapHint: String {
        guard let id = focusedGapID, let gap = gapChips.first(where: { $0.id == id }) else {
            return source == .fitbit
                ? "Tap a gap · wear Fitbit overnight, open Fitbit app, then pull-to-refresh Google Health."
                : "Tap a gap · grant Health access or switch source to Fitbit for Google Health sync."
        }
        switch gap.id {
        case "sleep":
            return "Sleep empty · wear overnight and sync Fitbit sleep stages to Google Health."
        case "hrv":
            return "HRV empty · continuous wear ≥4h overnight fills RMSSD."
        case "rhr":
            return "RHR empty · resting samples need quiet wake window after sleep."
        case "spo2":
            return "SpO₂ empty · enable SpO₂ in Fitbit settings; sync before morning readiness."
        case "resp":
            return "Resp empty · respiratory rate lands with overnight sleep session."
        case "skin":
            return "Skin empty · Sense/Charge skin temp needs overnight wear."
        case "steps":
            return "Steps empty · walk with Fitbit or phone; refresh air strip."
        case "kcal", "amin", "basal":
            return "\(gap.label) empty · activity + basal energy sync after daytime wear."
        case "dist":
            return "Distance empty · outdoor walk/run with GPS or phone co-presence."
        case "floors":
            return "Floors empty · climb stairs with altimeter-capable Fitbit."
        default:
            return "\(gap.label) · \(gap.detail)"
        }
    }

    /// Honest #506: steps-parity classic MetricDetail entry (defaults to Steps).
    private var chipMetricDetailLink: some View {
        let metric = selectedChip?.metric ?? MetricType.steps
        let value = QuickTrendCard.metricValue(data, metric: metric) ?? 0
        return NavigationLink(destination: MetricDetailView(
            metric: metric,
            currentValue: value,
            history: history,
            source: source
        )) {
            HStack(spacing: 10) {
                Image(systemName: metric.icon)
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(metric.rawValue) detail")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    Text("Open classic MetricDetail · Google Health / Fitbit air")
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .compositingGroup()
        .accessibilityIdentifier(SurfaceID.fitbitAirChipMetricDetail)
        .accessibilityLabel("\(metric.rawValue) metric detail")
    }

    @ViewBuilder
    private func selectedDetail(_ chip: AirChip) -> some View {
        let row = HStack(alignment: .top, spacing: 10) {
            Image(systemName: chip.icon)
                .foregroundStyle(accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(chip.label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(chip.metric != nil
                     ? "\(chip.detail) Tap for classic detail."
                     : chip.detail)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            Spacer()
            if chip.metric != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

        if let metric = chip.metric {
            let value = QuickTrendCard.metricValue(data, metric: metric) ?? 0
            NavigationLink(destination: MetricDetailView(
                metric: metric,
                currentValue: value,
                history: history,
                source: source
            )) {
                row
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(chip.label) metric detail")
        } else {
            row
        }
    }


    private var sparkBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(sparkMetric.title) · \(sparkPeriod)d")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                HStack(spacing: 4) {
                    ForEach([7, 14, 30], id: \.self) { days in
                        Button {
                            Haptic.selectionChanged()
                            sparkPeriod = days
                        } label: {
                            Text("\(days)d")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(sparkPeriod == days ? Color.white : accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(sparkPeriod == days ? accent : accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityIdentifier(SurfaceID.fitbitAirDataSparkPeriod)
            }
            // Honest #510: scrollable Steps/Sleep/HRV/Active/RHR/SpO₂ (+ SurfaceID spark.extra)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AirSparkMetric.allCases) { metric in
                        Button {
                            Haptic.selectionChanged()
                            sparkMetric = metric
                        } label: {
                            Text(metric.title)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(sparkMetric == metric ? Color.white : accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(sparkMetric == metric ? accent : accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Spark metric \(metric.title)")
                    }
                    // Invisible marker so #510 SurfaceID is unique & discoverable
                    Color.clear.frame(width: 1, height: 1)
                        .accessibilityIdentifier(SurfaceID.fitbitAirDataSparkExtra)
                        .accessibilityLabel("Spark metric extras")
                }
            }
            .accessibilityIdentifier(SurfaceID.fitbitAirDataSparkMetric)
            let scrubIdx = sparkScrubIndex ?? (sparkPoints.isEmpty ? nil : sparkPoints.count - 1)
            if let idx = scrubIdx, sparkPoints.indices.contains(idx) {
                let pt = sparkPoints[idx]
                HStack(spacing: 8) {
                    Text(pt.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                    Text(sparkScrubValueText(pt.value))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                    Spacer()
                    Text("scrub")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.tertiaryText)
                }
                .accessibilityIdentifier(SurfaceID.fitbitAirDataSparkScrub)
                .accessibilityLabel("Spark scrub \(sparkScrubValueText(pt.value))")
            }
            // Day chips — UITest-reliable scrub affordance (drag still works on chart).
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(sparkPoints.enumerated()), id: \.offset) { i, pt in
                        Button {
                            Haptic.selectionChanged()
                            sparkScrubIndex = i
                        } label: {
                            Text(pt.date, format: .dateTime.day())
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle((sparkScrubIndex ?? sparkPoints.count - 1) == i ? Color.white : accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((sparkScrubIndex ?? sparkPoints.count - 1) == i ? accent : accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(SurfaceID.fitbitAirDataSparkScrub)
                        .accessibilityLabel("Scrub day \(i + 1)")
                    }
                }
            }
            Chart {
                ForEach(Array(sparkPoints.enumerated()), id: \.offset) { i, pt in
                    AreaMark(
                        x: .value("Day", pt.date),
                        y: .value(sparkMetric.title, pt.value)
                    )
                    .foregroundStyle(accent.opacity(0.25))
                    LineMark(
                        x: .value("Day", pt.date),
                        y: .value(sparkMetric.title, pt.value)
                    )
                    .foregroundStyle(accent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    if (sparkScrubIndex ?? sparkPoints.count - 1) == i {
                        PointMark(
                            x: .value("Day", pt.date),
                            y: .value(sparkMetric.title, pt.value)
                        )
                        .foregroundStyle(accent)
                        .symbolSize(64)
                    }
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 64)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    sparkSelect(at: value.location, proxy: proxy, geo: geo)
                                }
                                .onEnded { _ in
                                    // Keep last scrub visible for a beat of richness; clear on next period/metric change.
                                }
                        )
                }
            }
            .animation(.easeInOut(duration: 0.25), value: sparkPeriod)
            .animation(.easeInOut(duration: 0.25), value: sparkMetric)
            .accessibilityIdentifier(SurfaceID.fitbitAirDataSpark)
            .onChange(of: sparkPeriod) { _ in sparkScrubIndex = nil }
            .onChange(of: sparkMetric) { _ in sparkScrubIndex = nil }
        }
    }

    private func sparkScrubValueText(_ value: Double) -> String {
        switch sparkMetric {
        case .steps: return "\(Int(value.rounded()))"
        case .sleep: return String(format: "%.1fh", value)
        case .hrv: return "\(Int(value.rounded())) ms"
        case .active: return "\(Int(value.rounded())) kcal"
        case .rhr: return "\(Int(value.rounded())) bpm"
        case .spo2: return String(format: "%.0f%%", value)
        }
    }

    private func sparkSelect(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        guard sparkPoints.count >= 1 else { return }
        let width = max(geo.size.width, 1)
        let frac = min(max(location.x / width, 0), 1)
        let best: Int
        if sparkPoints.count == 1 {
            best = 0
        } else {
            best = min(sparkPoints.count - 1, max(0, Int((frac * CGFloat(sparkPoints.count - 1)).rounded())))
        }
        _ = proxy  // keep chartOverlay signature; fraction scrub is iOS-16-safe
        if sparkScrubIndex != best {
            sparkScrubIndex = best
            Haptic.selectionChanged()
        }
    }
}

// MARK: - Spark metric (Honest #505)

enum AirSparkMetric: String, CaseIterable, Identifiable {
    case steps, sleep, hrv, active, rhr, spo2
    var id: String { rawValue }
    var title: String {
        switch self {
        case .steps: return "Steps"
        case .sleep: return "Sleep"
        case .hrv: return "HRV"
        case .active: return "Active"
        case .rhr: return "RHR"
        case .spo2: return "SpO₂"
        }
    }
    func value(from day: DailyHealthData) -> Double {
        switch self {
        case .steps: return Double(day.steps)
        case .sleep: return day.sleepHours
        case .hrv: return day.hrv
        case .active: return day.activeCalories
        case .rhr: return Double(day.restingHeartRate)
        case .spo2: return day.bloodOxygen ?? 0
        }
    }
}


// MARK: - Density legend categories (Honest #513)

enum AirDensityCategory: String, CaseIterable, Identifiable {
    case sleep, vitals, activity
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sleep: return "Sleep"
        case .vitals: return "Vitals"
        case .activity: return "Move"
        }
    }
    var shortTitle: String {
        switch self {
        case .sleep: return "SLP"
        case .vitals: return "VIT"
        case .activity: return "MOV"
        }
    }
    var color: Color {
        switch self {
        case .sleep: return Color(hex: "5E5CE6")
        case .vitals: return Color(hex: "FF375F")
        case .activity: return Color(hex: "00B0B9")
        }
    }
    var chipIDs: [String] {
        switch self {
        case .sleep: return ["sleep"]
        case .vitals: return ["hrv", "rhr", "spo2", "resp", "skin"]
        case .activity: return ["steps", "kcal", "dist", "floors", "amin", "basal"]
        }
    }
    /// Honest #517: primary spark metric when legend focuses this category.
    var sparkMetric: AirSparkMetric {
        switch self {
        case .sleep: return .sleep
        case .vitals: return .hrv
        case .activity: return .steps
        }
    }
    func filledCount(in chips: [AirChip]) -> Int {
        chips.filter { chipIDs.contains($0.id) && $0.filled }.count
    }
    func fillRatio(in chips: [AirChip]) -> Double {
        guard !chipIDs.isEmpty else { return 0 }
        return Double(filledCount(in: chips)) / Double(chipIDs.count)
    }
}

// MARK: - Chips

struct AirChip: Identifiable {
    let id: String
    let label: String
    let valueText: String
    let detail: String
    let icon: String
    let filled: Bool
    /// Honest #506: classic MetricDetail destination when set.
    let metric: MetricType?

    static func all(from data: DailyHealthData) -> [AirChip] {
        let spo2 = data.bloodOxygen
        let resp = data.respiratoryRate
        let skin = data.skinTemperature
        let dist = data.distanceWalkingRunningKm
        let floors = data.flightsClimbed
        let activeMin = data.appleExerciseTimeMinutes
        let basal = data.basalEnergyKcal
        return [
            .init(id: "sleep", label: "Sleep",
                  valueText: data.sleepHours > 0 ? String(format: "%.1fh", data.sleepHours) : "—",
                  detail: "Night sleep hours from Google Health / HealthKit.",
                  icon: "moon.zzz.fill", filled: data.sleepHours > 0, metric: .sleep),
            .init(id: "hrv", label: "HRV",
                  valueText: data.hrv > 0 ? "\(Int(data.hrv)) ms" : "—",
                  detail: "RMSSD heart-rate variability.",
                  icon: "waveform.path.ecg", filled: data.hrv > 0, metric: .hrv),
            .init(id: "rhr", label: "RHR",
                  valueText: data.restingHeartRate > 0 ? "\(data.restingHeartRate)" : "—",
                  detail: "Resting heart rate (bpm).",
                  icon: "heart.fill", filled: data.restingHeartRate > 0, metric: .restingHR),
            .init(id: "spo2", label: "SpO₂",
                  valueText: (spo2 ?? 0) > 0 ? String(format: "%.0f%%", spo2!) : "—",
                  detail: "Blood oxygen average.",
                  icon: "lungs.fill", filled: (spo2 ?? 0) > 0, metric: .bloodOxygen),
            .init(id: "resp", label: "Resp",
                  valueText: (resp ?? 0) > 0 ? String(format: "%.1f", resp!) : "—",
                  detail: "Respiratory rate (breaths/min).",
                  icon: "wind", filled: (resp ?? 0) > 0, metric: .respiratoryRate),
            .init(id: "skin", label: "Skin",
                  valueText: skin != nil ? String(format: "%+.1f°", skin!) : "—",
                  detail: "Skin temperature deviation (°C).",
                  icon: "thermometer.medium", filled: skin != nil, metric: .skinTemperature),
            .init(id: "steps", label: "Steps",
                  valueText: data.steps > 0 ? "\(data.steps)" : "—",
                  detail: "Step count today.",
                  icon: "figure.walk", filled: data.steps > 0, metric: .steps),
            .init(id: "kcal", label: "Active",
                  valueText: data.activeCalories > 0 ? "\(Int(data.activeCalories))" : "—",
                  detail: "Active energy (kcal).",
                  icon: "flame.fill", filled: data.activeCalories > 0, metric: .activeCalories),
            .init(id: "dist", label: "Dist",
                  valueText: (dist ?? 0) > 0 ? String(format: "%.1f km", dist!) : "—",
                  detail: "Walking + running distance.",
                  icon: "map", filled: (dist ?? 0) > 0, metric: .walkingDistance),
            .init(id: "floors", label: "Floors",
                  valueText: (floors ?? 0) > 0 ? "\(Int(floors!))" : "—",
                  detail: "Floors / flights climbed.",
                  icon: "figure.stairs", filled: (floors ?? 0) > 0, metric: .flightsClimbed),
            .init(id: "amin", label: "Active′",
                  valueText: (activeMin ?? 0) > 0 ? "\(Int(activeMin!))m" : "—",
                  detail: "Active minutes (exercise).",
                  icon: "timer", filled: (activeMin ?? 0) > 0, metric: .exerciseTime),
            .init(id: "basal", label: "Basal",
                  valueText: (basal ?? 0) > 0 ? "\(Int(basal!))" : "—",
                  detail: "Basal energy (kcal).",
                  icon: "leaf.fill", filled: (basal ?? 0) > 0, metric: .basalEnergy),
        ]
    }
}
