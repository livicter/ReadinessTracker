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
    /// Honest #519: show spark delta as percent vs absolute.
    @State private var sparkDeltaAsPercent: Bool = false
    /// Honest #509: which air gap pill is expanded.
    @State private var focusedGapID: String? = nil
    /// Honest #513: density legend category focus (Sleep / Vitals / Activity).
    @State private var focusedLegend: AirDensityCategory? = nil
    /// Honest #526: which heatmap day is selected (index into last 7).
    @State private var selectedHeatDayOffset: Int? = nil
    /// Honest #527: expand week-over-week density detail.
    /// Honest #534: expand density forecast detail.
    @State private var showDensityForecastDetail: Bool = false
    @State private var showDensityWowDetail: Bool = false
    /// Honest #538: expand density streak detail.
    @State private var showDensityStreakDetail: Bool = false
    /// Honest #630: Google Health–style density detail sheet.
    @State private var showDensityDetailSheet: Bool = false
    /// Honest #632: Health Air Today scrub index (Apple Health glance parity with #630 sheet).
    @State private var healthScrubIndex: Int? = nil
    /// Honest #633: Health Air glance category overlay toggles (#631 sheet parity).
    @State private var healthVisibleCats: Set<AirDensityCategory> = Set(AirDensityCategory.allCases)
    /// Honest #634: Health Air glance period (7/14/30d) — #630 detail sheet parity.
    @State private var healthPeriod: Int = 14

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
        if let id = selectedChipID, let match = chips.first(where: { $0.id == id }) {
            return match
        }
        // Honest #544: default to first filled metric chip so mini-spark + range mount without a tap
        return chips.first { $0.filled && $0.metric != nil }
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
                densityStackedBar
                densityHeatmap
                densityWowBadge
                densityForecastBadge
                densityStreakBadge
                densityHistorySpark
                densityDistributionHist
                densityCVMeter
                densitySkewMeter
                densityIQRMeter
                densityPercentileMeter
                densityEnvelopeChart
                densityMADMeter
                densityTukeyFences
                densitySlopeMeter
                densityZScoreStrip
                densityACFMeter
                densityEntropyMeter
                densityKurtosisMeter
                densitySpanMeter
                densityGiniMeter
                densityVolatilityMeter
                densityOutlierMeter
                densityHHIMeter
                densityDrawdownMeter
                densityReboundMeter
                densitySharpeMeter
                densitySortinoMeter
                densityCalmarMeter
                densityOmegaMeter
                densityUlcerMeter
                densitySterlingMeter
                densityBurkeMeter
                densityMartinMeter
                densityKappaMeter
                densityGainPainMeter
                densityTailMeter
                // Honest #632: Apple Health / HealthKit Today glance — scrub + Gain/Pain (#630 sheet parity)
                // Placed after forecast/density meters so early UITest scroll to forecast.band stays stable.
                if source == .appleWatch {
                    healthAirDensityGlance
                }
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
        .sheet(isPresented: $showDensityDetailSheet) {
            FitbitAirDensityDetailSheet(history: history, source: source)
        }
    }


    /// Honest #632: Health Air Today — Google Health–style density scrub + Gain/Pain wells
    /// (parity with Fitbit #630 detail sheet, on-card for HealthKit / Apple Watch source).
    private var healthAirDensityGlance: some View {
        let healthAccent = Color(hex: "FF2D55")  // Apple Health pink
        let days = Array(history.suffix(healthPeriod))
        let densSeries: [(date: Date, density: Double)] = days.map { day in
            let chips = AirChip.all(from: day)
            let d: Double
            if chips.isEmpty { d = 0 }
            else { d = Double(chips.filter(\.filled).count) / Double(chips.count) }
            return (date: day.date, density: d)
        }
        let active = healthScrubIndex ?? max(0, densSeries.count - 1)
        let dens = densSeries.map(\.density)
        // Gain/Pain from day deltas
        var up = 0.0
        var down = 0.0
        var deltas: [Double] = []
        if dens.count >= 2 {
            for i in 1..<dens.count {
                let dlt = dens[i] - dens[i - 1]
                deltas.append(dlt)
                if dlt >= 0 { up += dlt } else { down += -dlt }
            }
        }
        let gp = down < 1e-6 ? (up > 0 ? 4.0 : 0.0) : up / down
        let verb: String
        let tone: Color
        if gp >= 2.0 { verb = "Bull"; tone = RTColor.optimal }
        else if gp >= 1.0 { verb = "Net+"; tone = RTColor.good }
        else if gp >= 0.5 { verb = "Mixed"; tone = RTColor.caution }
        else { verb = "Bleed"; tone = RTColor.warning }
        let disp = String(format: "%.2f", gp)
        let maxAbs = max(deltas.map { abs($0) }.max() ?? 0.01, 0.01)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Health density")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("Apple Health")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(healthAccent)
                if densSeries.indices.contains(active) {
                    Text("\(Int((densSeries[active].density * 100).rounded()))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(RTColor.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(healthAccent.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            // Honest #634: 7/14/30d period picker (#630 detail sheet parity)
            HStack(spacing: 8) {
                ForEach([7, 14, 30], id: \.self) { p in
                    Button {
                        Haptic.selectionChanged()
                        healthPeriod = p
                        healthScrubIndex = nil
                    } label: {
                        Text("\(p)d")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(healthPeriod == p ? Color.white : healthAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(healthPeriod == p ? healthAccent : healthAccent.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Health density \(p) day period")
                }
                Spacer()
                Text("\(healthPeriod)d window")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.tertiaryText)
            }
            .accessibilityIdentifier(SurfaceID.healthAirDensityPeriod)
            .accessibilityLabel("Health density period picker")
            if densSeries.count >= 2 {
                Chart {
                    ForEach(Array(densSeries.enumerated()), id: \.offset) { i, pt in
                        AreaMark(
                            x: .value("Day", pt.date),
                            y: .value("Density", pt.density)
                        )
                        .foregroundStyle(healthAccent.opacity(0.14))
                        LineMark(
                            x: .value("Day", pt.date),
                            y: .value("Density", pt.density)
                        )
                        .foregroundStyle(healthAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2.25, lineCap: .round))
                        if i == active {
                            RuleMark(x: .value("Scrub", pt.date))
                                .foregroundStyle(RTColor.secondaryText.opacity(0.4))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            PointMark(
                                x: .value("Day", pt.date),
                                y: .value("Density", pt.density)
                            )
                            .foregroundStyle(healthAccent)
                            .symbolSize(64)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 110)
                .chartOverlay { _ in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let count = densSeries.count
                                        guard count >= 1 else { return }
                                        let width = max(geo.size.width, 1)
                                        let frac = min(max(value.location.x / width, 0), 1)
                                        let best = count == 1 ? 0 : min(count - 1, max(0, Int((frac * CGFloat(count - 1)).rounded())))
                                        if healthScrubIndex != best {
                                            healthScrubIndex = best
                                            Haptic.selectionChanged()
                                        }
                                    }
                            )
                    }
                }
                .accessibilityIdentifier(SurfaceID.healthAirDensityScrub)
                .accessibilityLabel("Health density scrub")
            } else {
                Text("Need more HealthKit history for density scrub")
                    .font(.caption)
                    .foregroundStyle(RTColor.tertiaryText)
            }
            // Gain/Pain wells
            if deltas.count >= 4 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Gain / Pain")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                        Spacer()
                        Text("\(verb) \(disp)")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(tone)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tone.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    GeometryReader { geo in
                        let w = max(geo.size.width, 1)
                        let h = max(geo.size.height, 1)
                        let n = max(deltas.count, 1)
                        let bw = w / Double(n)
                        let midY = h / 2
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: midY))
                            p.addLine(to: CGPoint(x: w, y: midY))
                        }
                        .stroke(RTColor.tertiaryText.opacity(0.35), lineWidth: 1)
                        ForEach(Array(deltas.enumerated()), id: \.offset) { i, dlt in
                            let bh = (abs(dlt) / maxAbs) * (h * 0.45)
                            let x = bw * (Double(i) + 0.5)
                            let y = dlt >= 0 ? midY - bh : midY
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(dlt >= 0 ? RTColor.optimal.opacity(0.85) : RTColor.warning.opacity(0.85))
                                .frame(width: max(3, bw * 0.7), height: max(2, bh))
                                .position(x: x, y: y + bh / 2)
                        }
                    }
                    .frame(height: 72)
                    HStack(spacing: 8) {
                        healthWellStat(title: "Σ Gain", value: String(format: "+%.2f", up), color: RTColor.optimal)
                        healthWellStat(title: "Σ Pain", value: String(format: "−%.2f", down), color: RTColor.warning)
                        healthWellStat(title: "Ratio", value: disp, color: tone)
                    }
                }
                .accessibilityIdentifier(SurfaceID.healthAirDensityGainPain)
                .accessibilityLabel("Health Gain Pain \(verb) \(disp)")
            }
            // Honest #633: Sleep / Vitals / Move density overlays (#631 sheet parity, on-card)
            healthCategoryOverlay(days: days, active: active, healthAccent: healthAccent)
        }
        .padding(12)
        .background(RTColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(healthAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.healthAirDensityGlance)
        .accessibilityLabel("Health Air density glance")
    }

    /// Honest #633: Health Air category density overlays (Sleep / Vitals / Move).
    private func healthCategoryOverlay(days: [DailyHealthData], active: Int, healthAccent: Color) -> some View {
        let catSeries: [(cat: AirDensityCategory, points: [(date: Date, density: Double)])] = AirDensityCategory.allCases.map { cat in
            let pts = days.map { day -> (date: Date, density: Double) in
                let chips = AirChip.all(from: day)
                return (date: day.date, density: cat.fillRatio(in: chips))
            }
            return (cat: cat, points: pts)
        }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Category density")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("Health overlay")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(healthAccent)
            }
            HStack(spacing: 8) {
                ForEach(AirDensityCategory.allCases) { cat in
                    let on = healthVisibleCats.contains(cat)
                    Button {
                        Haptic.selectionChanged()
                        if on {
                            if healthVisibleCats.count > 1 { healthVisibleCats.remove(cat) }
                        } else {
                            healthVisibleCats.insert(cat)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(cat.color).frame(width: 8, height: 8)
                            Text(cat.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(on ? RTColor.primaryText : RTColor.tertiaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(on ? cat.color.opacity(0.14) : RTColor.surfaceHighlight.opacity(0.5))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(on ? cat.color.opacity(0.45) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(cat.title) Health overlay \(on ? "on" : "off")")
                }
            }
            if days.count >= 2 {
                Chart {
                    ForEach(catSeries, id: \.cat.id) { item in
                        if healthVisibleCats.contains(item.cat) {
                            ForEach(Array(item.points.enumerated()), id: \.offset) { i, pt in
                                LineMark(
                                    x: .value("Day", pt.date),
                                    y: .value("Density", pt.density),
                                    series: .value("Cat", item.cat.title)
                                )
                                .foregroundStyle(item.cat.color)
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                                if i == active {
                                    PointMark(
                                        x: .value("Day", pt.date),
                                        y: .value("Density", pt.density)
                                    )
                                    .foregroundStyle(item.cat.color)
                                    .symbolSize(48)
                                }
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 110)
                .chartOverlay { _ in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let count = days.count
                                        guard count >= 1 else { return }
                                        let width = max(geo.size.width, 1)
                                        let frac = min(max(value.location.x / width, 0), 1)
                                        let best = count == 1 ? 0 : min(count - 1, max(0, Int((frac * CGFloat(count - 1)).rounded())))
                                        if healthScrubIndex != best {
                                            healthScrubIndex = best
                                            Haptic.selectionChanged()
                                        }
                                    }
                            )
                    }
                }
                if days.indices.contains(active) {
                    HStack(spacing: 8) {
                        ForEach(AirDensityCategory.allCases) { cat in
                            if healthVisibleCats.contains(cat) {
                                let chips = AirChip.all(from: days[active])
                                let r = cat.fillRatio(in: chips)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cat.shortTitle)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(cat.color)
                                    Text("\(Int((r * 100).rounded()))%")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(RTColor.primaryText)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(cat.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
            } else {
                Text("Need more HealthKit history for category overlays")
                    .font(.caption)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .accessibilityIdentifier(SurfaceID.healthAirDensityCats)
        .accessibilityLabel("Health category density overlays")
    }

    private func healthWellStat(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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
            // Honest #630: open Google Health–style density detail sheet
            Button {
                Haptic.selectionChanged()
                showDensityDetailSheet = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.caption2.weight(.semibold))
                    Text("Detail")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(accent.opacity(0.12))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(source == .appleWatch
                                     ? SurfaceID.healthAirDensityDetailOpen
                                     : SurfaceID.fitbitAirDensityDetailOpen)
            .accessibilityLabel(source == .appleWatch
                                ? "Open Health air density detail"
                                : "Open air density detail")
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
        .contentShape(Circle())
        .onTapGesture { cycleDensityLegendFocus() }
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityRingCycle)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Air density \(Int((density * 100).rounded())) percent, tap to cycle category")
        .accessibilityHint("Cycles Sleep, Vitals, Activity focus")
    }

    /// Honest #521: tap density ring to cycle legend focus + spark link.
    private func cycleDensityLegendFocus() {
        Haptic.selectionChanged()
        let order = AirDensityCategory.allCases
        if let cur = focusedLegend, let idx = order.firstIndex(of: cur) {
            let next = idx + 1
            focusedLegend = next < order.count ? order[next] : nil
        } else {
            focusedLegend = order.first
        }
        if let focus = focusedLegend {
            let ids = focus.chipIDs
            selectedChipID = chips.first(where: { ids.contains($0.id) && $0.filled })?.id
                ?? chips.first(where: { ids.contains($0.id) })?.id
            sparkMetric = focus.sparkMetric
            sparkScrubIndex = nil
        }
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

    /// Honest #529: interactive Sleep/Vitals/Activity stacked density bar.
    private var densityStackedBar: some View {
        GeometryReader { geo in
            let totalW = max(geo.size.width, 1)
            let weights = AirDensityCategory.allCases.map { max(0.08, $0.fillRatio(in: chips)) }
            let sum = weights.reduce(0, +)
            HStack(spacing: 3) {
                ForEach(Array(AirDensityCategory.allCases.enumerated()), id: \.element.id) { idx, cat in
                    let w = totalW * (weights[idx] / max(sum, 0.01))
                    Button {
                        Haptic.selectionChanged()
                        focusedLegend = focusedLegend == cat ? nil : cat
                        if let focus = focusedLegend {
                            let ids = focus.chipIDs
                            selectedChipID = chips.first(where: { ids.contains($0.id) && $0.filled })?.id
                                ?? chips.first(where: { ids.contains($0.id) })?.id
                            sparkMetric = focus.sparkMetric
                            sparkScrubIndex = nil
                        }
                    } label: {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(cat.color.opacity(focusedLegend == nil || focusedLegend == cat ? 0.85 : 0.35))
                            Text(cat.shortTitle)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 6)
                        }
                        .frame(width: max(28, w - 3), height: 28)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(focusedLegend == cat ? Color.white.opacity(0.9) : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(cat.title) stack \(Int((cat.fillRatio(in: chips) * 100).rounded())) percent")
                }
            }
        }
        .frame(height: 28)
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityStack)
        .accessibilityLabel("Air density category stack")
        .accessibilityElement(children: .contain)
    }

    /// Honest #525/#526: interactive 7-day density heatmap; tap selects day + scrub spark.
    private var densityHeatmap: some View {
        let days = Array(history.suffix(7))
        return VStack(alignment: .leading, spacing: 8) {
            Text("7-day density")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            HStack(spacing: 6) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, day in
                    let dayChips = AirChip.all(from: day)
                    let filled = dayChips.filter(\.filled).count
                    let dens = dayChips.isEmpty ? 0.0 : Double(filled) / Double(dayChips.count)
                    let selected = selectedHeatDayOffset == i
                    Button {
                        Haptic.selectionChanged()
                        selectedHeatDayOffset = selectedHeatDayOffset == i ? nil : i
                        let sparkDays = sparkPoints
                        if let match = sparkDays.firstIndex(where: {
                            Calendar.current.isDate($0.date, inSameDayAs: day.date)
                        }) {
                            sparkScrubIndex = match
                        }
                    } label: {
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(heatmapColor(dens))
                                .frame(height: 36)
                                .overlay(
                                    Text("\(Int((dens * 100).rounded()))")
                                        .font(.caption2.weight(.bold).monospacedDigit())
                                        .foregroundStyle(dens > 0.55 ? Color.white : RTColor.primaryText)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(selected ? accent : Color.clear, lineWidth: 2)
                                )
                            Text(day.date, format: .dateTime.weekday(.narrow))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(selected ? accent : RTColor.tertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Density day \(i + 1) \(Int((dens * 100).rounded())) percent")
                }
            }
            if let idx = selectedHeatDayOffset, days.indices.contains(idx) {
                heatmapDayStrip(days[idx])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityHeatmap)
        .accessibilityLabel("Seven day air density heatmap")
    }

    /// Honest #526: selected heatmap day chip-dot strip.
    private func heatmapDayStrip(_ day: DailyHealthData) -> some View {
        let dayChips = AirChip.all(from: day)
        let filled = dayChips.filter(\.filled).count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(filled)/\(dayChips.count) fields")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
            }
            HStack(spacing: 4) {
                ForEach(dayChips) { chip in
                    Circle()
                        .fill(chip.filled ? accent : RTColor.surfaceHighlight)
                        .frame(width: 8, height: 8)
                        .accessibilityLabel("\(chip.label) \(chip.filled ? "filled" : "gap")")
                }
            }
        }
        .padding(10)
        .background(RTColor.surfaceHighlight, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityHeatDay)
        .accessibilityLabel("Selected density day field strip")
    }

    private func heatmapColor(_ dens: Double) -> Color {
        if dens <= 0 { return RTColor.surfaceHighlight }
        if dens < 0.4 { return accent.opacity(0.25) }
        if dens < 0.7 { return accent.opacity(0.55) }
        return accent.opacity(0.9)
    }


    /// Honest #534: linear density forecast for tomorrow from last 7d trend.
    private var densityForecast: (tomorrow: Double, slopePP: Double, today: Double, lo: Double, hi: Double)? {
        let days = Array(history.suffix(7))
        guard days.count >= 4 else { return nil }
        let dens: [Double] = days.map { day in
            let c = AirChip.all(from: day)
            guard !c.isEmpty else { return 0 }
            return Double(c.filter(\.filled).count) / Double(c.count)
        }
        let n = Double(dens.count)
        let xs = dens.indices.map { Double($0) }
        let sumX = xs.reduce(0, +)
        let sumY = dens.reduce(0, +)
        let sumXY = zip(xs, dens).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        guard abs(denom) > 1e-9 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n
        let tomorrow = min(1, max(0, intercept + slope * n))
        let today = dens.last ?? 0
        // Honest #540: ±1σ residual band around tomorrow
        var sse: Double = 0
        for (x, y) in zip(xs, dens) {
            let err = y - (intercept + slope * x)
            sse += err * err
        }
        let dof = Double(max(1, dens.count - 2))
        let rmse: Double = Darwin.sqrt(sse / dof)
        let lo = min(1.0, max(0.0, tomorrow - rmse))
        let hi = min(1.0, max(0.0, tomorrow + rmse))
        return (tomorrow, slope * 100, today, lo, hi)
    }

    @ViewBuilder
    private var densityForecastBadge: some View {
        if let fc = densityForecast {
            let deltaPP = (fc.tomorrow - fc.today) * 100
            let sign = deltaPP >= 0 ? "+" : ""
            let tone: Color = abs(deltaPP) < 0.5 ? RTColor.secondaryText
                : (deltaPP > 0 ? RTColor.optimal : RTColor.warning)
            // Honest #558: forecast vs window mean density (Google Health air graphics)
            let meanVals = densityHistoryPoints.map(\.density).filter { $0 > 0 }
            let winMean = meanVals.isEmpty ? 0.0 : meanVals.reduce(0, +) / Double(meanVals.count)
            let vsMeanPP = winMean > 0 ? (fc.tomorrow - winMean) * 100 : 0
            let vsSign = vsMeanPP >= 0 ? "+" : ""
            let vsTone: Color = abs(vsMeanPP) < 3 ? RTColor.secondaryText
                : (vsMeanPP >= 0 ? RTColor.optimal : RTColor.warning)
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    Haptic.selectionChanged()
                    showDensityForecastDetail.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.semibold))
                        Text("Tomorrow density")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text("\(Int((fc.tomorrow * 100).rounded()))%")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(accent)
                        Text("\(sign)\(Int(deltaPP.rounded()))pp")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(tone)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tone.opacity(0.12))
                            .clipShape(Capsule())
                        if winMean > 0 {
                            Text("vs avg \(vsSign)\(Int(vsMeanPP.rounded()))pp")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(vsTone)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(vsTone.opacity(0.12))
                                .clipShape(Capsule())
                                .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastVsMean)
                                .accessibilityLabel("Forecast versus mean \(vsSign)\(Int(vsMeanPP.rounded())) percentage points")
                        }
                        Image(systemName: showDensityForecastDetail ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .foregroundStyle(accent)
                    .padding(10)
                    .background(RTColor.surfaceHighlight, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                if showDensityForecastDetail {
                    HStack(spacing: 12) {
                        wowStat(title: "Today", value: "\(Int((fc.today * 100).rounded()))%")
                        wowStat(title: "Slope/d", value: String(format: "%+.1fpp", fc.slopePP))
                        wowStat(title: "Tomorrow", value: "\(Int((fc.tomorrow * 100).rounded()))%")
                        if winMean > 0 {
                            wowStat(title: "vs mean", value: "\(vsSign)\(Int(vsMeanPP.rounded()))pp")
                        }
                    }
                    densityForecastBandRow(lo: fc.lo, hi: fc.hi)
                    densityForecastBandBar(lo: fc.lo, hi: fc.hi, tomorrow: fc.tomorrow)
                    // Honest #560: forecast confidence from residual band width (Google Health graphics)
                    densityForecastConfidenceMeter(lo: fc.lo, hi: fc.hi)
                    // Honest #562: 3-day forecast horizon bars (Google Health graphics)
                    densityForecastHorizon(fc: fc)
                    // Honest #564: residual spark — actual vs predicted density (Google Health)
                    densityForecastResidualSpark()
                    // Honest #566: forecast hit-rate — actuals inside residual band (Google Health)
                    densityForecastHitRate()
                    // Honest #568: residual bias — signed mean residual over/under (Google Health)
                    densityForecastResidualBias()
                }
            }
            .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecast)
            .accessibilityLabel("Tomorrow density forecast \(Int((fc.tomorrow * 100).rounded())) percent")
            .accessibilityAddTraits(.isButton)
        }
    }

    /// Honest #540: ±1σ residual band row (split out for type-checker).
    private func densityForecastBandRow(lo: Double, hi: Double) -> some View {
        let loPct = Int((lo * 100).rounded())
        let hiPct = Int((hi * 100).rounded())
        return HStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.caption2.weight(.semibold))
            Text("Band")
                .font(.caption2.weight(.semibold))
            Spacer()
            Text("\(loPct)–\(hiPct)%")
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(accent)
        }
        .foregroundStyle(RTColor.secondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastBand)
        .accessibilityLabel("Tomorrow density band \(loPct) to \(hiPct) percent")
    }


    /// Honest #542: visual 0–100% track with ±1σ band fill + tomorrow marker.
    private func densityForecastBandBar(lo: Double, hi: Double, tomorrow: Double) -> some View {
        let loC = min(1, max(0, lo))
        let hiC = min(1, max(0, hi))
        let mid = min(1, max(0, tomorrow))
        return GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(RTColor.tertiaryText.opacity(0.18))
                Capsule()
                    .fill(accent.opacity(0.28))
                    .frame(width: max(4, (hiC - loC) * w))
                    .offset(x: loC * w)
                Circle()
                    .fill(accent)
                    .frame(width: 10, height: 10)
                    .offset(x: max(0, mid * w - 5))
            }
        }
        .frame(height: 10)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastBar)
        .accessibilityLabel("Tomorrow density band bar \(Int((loC * 100).rounded())) to \(Int((hiC * 100).rounded())) percent, marker \(Int((mid * 100).rounded()))")
    }


    /// Honest #560: confidence meter — narrower ±1σ band ⇒ higher confidence.
    private func densityForecastConfidenceMeter(lo: Double, hi: Double) -> some View {
        let span = max(0, min(1, hi - lo))
        let conf = max(0, min(1, 1 - span))  // 0% span → 100% conf
        let pct = Int((conf * 100).rounded())
        let tone: Color = conf >= 0.75 ? RTColor.optimal
            : (conf >= 0.45 ? RTColor.good : RTColor.warning)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(tone)
                Text("Confidence")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(pct)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.14))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RTColor.tertiaryText.opacity(0.16))
                        .frame(height: 10)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [tone.opacity(0.55), tone],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(6, geo.size.width * CGFloat(conf)), height: 10)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 12)
            Text(span < 0.15 ? "Tight band · high trust"
                 : (span < 0.35 ? "Moderate residual spread" : "Wide band · low trust"))
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(10)
        .background(tone.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(tone.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastConf)
        .accessibilityLabel("Forecast confidence \(pct) percent")
    }


    /// Honest #562: 3-day ahead density horizon bars with tapering confidence (Google Health).
    private func densityForecastHorizon(fc: (tomorrow: Double, slopePP: Double, today: Double, lo: Double, hi: Double)) -> some View {
        let slope = fc.slopePP / 100.0  // per-day density fraction
        let days: [(label: String, value: Double, conf: Double)] = (1...3).map { d in
            let v = min(1, max(0, fc.today + slope * Double(d)))
            // confidence tapers with horizon; also shrinks when residual band is wide
            let span = max(0, min(1, fc.hi - fc.lo))
            let baseConf = max(0, min(1, 1 - span))
            let taper = max(0.25, 1.0 - 0.22 * Double(d - 1))
            return ("D+\(d)", v, baseConf * taper)
        }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Horizon")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("3-day")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.12))
                    .clipShape(Capsule())
            }
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 6) {
                        Text("\(Int((day.value * 100).rounded()))%")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(accent.opacity(0.55 + 0.45 * day.conf))
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accent.opacity(0.35 * day.conf), accent.opacity(0.85 * day.conf + 0.15)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(8, 72 * day.value))
                            .frame(maxWidth: .infinity)
                        Text(day.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(RTColor.secondaryText)
                        Text("\(Int((day.conf * 100).rounded()))% conf")
                            .font(.system(size: 9, weight: .medium).monospacedDigit())
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110, alignment: .bottom)
            Text("Slope \(String(format: "%+.1f", fc.slopePP))pp/d · confidence tapers with horizon")
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastHorizon)
        .accessibilityLabel("Density forecast horizon three day")
    }

    /// Honest #564: residual spark — last-7 actual density vs linear prediction (Google Health graphics).
    @ViewBuilder
    private func densityForecastResidualSpark() -> some View {
        let days = Array(history.suffix(7))
        if days.count < 4 {
            EmptyView()
        } else {
            residualSparkBody(days: days)
        }
    }

    private func residualSparkBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let xs = dens.indices.map { Double($0) }
        let sumX = xs.reduce(0, +)
        let sumY = dens.reduce(0, +)
        let sumXY = zip(xs, dens).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        let slope: Double
        let intercept: Double
        if abs(denom) > 1e-9 {
            slope = (n * sumXY - sumX * sumY) / denom
            intercept = (sumY - slope * sumX) / n
        } else {
            slope = 0
            intercept = dens.last ?? 0
        }
        struct Pt: Identifiable {
            let id: Int
            let label: String
            let actual: Double
            let predicted: Double
        }
        let points: [Pt] = dens.enumerated().map { i, a in
            Pt(id: i, label: "D-\(dens.count - 1 - i)", actual: a, predicted: intercept + slope * Double(i))
        }
        let mae = points.map { abs($0.actual - $0.predicted) }.reduce(0, +) / Double(max(1, points.count))
        let maePP = Int((mae * 100).rounded())
        let maeTone: Color = maePP <= 8 ? RTColor.optimal : (maePP <= 15 ? RTColor.good : RTColor.warning)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Residual")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("MAE \(maePP)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(maeTone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(maeTone.opacity(0.12))
                    .clipShape(Capsule())
            }
            Chart {
                ForEach(points) { pt in
                    LineMark(
                        x: .value("Day", pt.label),
                        y: .value("Actual", pt.actual * 100)
                    )
                    .foregroundStyle(accent)
                    .interpolationMethod(.catmullRom)
                    .symbol(Circle())
                    .symbolSize(36)
                    LineMark(
                        x: .value("Day", pt.label),
                        y: .value("Predicted", pt.predicted * 100)
                    )
                    .foregroundStyle(RTColor.secondaryText.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    .interpolationMethod(.linear)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(RTColor.divider)
                    AxisValueLabel()
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(RTColor.secondaryText)
                        .font(.caption2)
                }
            }
            .frame(height: 88)
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Capsule().fill(accent).frame(width: 12, height: 3)
                    Text("Actual")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                HStack(spacing: 4) {
                    Capsule()
                        .stroke(RTColor.secondaryText.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                        .frame(width: 12, height: 3)
                    Text("Predicted")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                Spacer()
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastResidual)
        .accessibilityLabel("Forecast residual spark mean absolute error \(maePP) percentage points")
    }


    /// Honest #566: forecast hit-rate — share of last-7 actuals inside residual band (Google Health graphics).
    @ViewBuilder
    private func densityForecastHitRate() -> some View {
        let days = Array(history.suffix(7))
        if days.count < 4 {
            EmptyView()
        } else {
            hitRateBody(days: days)
        }
    }

    private func hitRateBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let xs = dens.indices.map { Double($0) }
        let sumX = xs.reduce(0, +)
        let sumY = dens.reduce(0, +)
        let sumXY = zip(xs, dens).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        let slope: Double
        let intercept: Double
        if abs(denom) > 1e-9 {
            slope = (n * sumXY - sumX * sumY) / denom
            intercept = (sumY - slope * sumX) / n
        } else {
            slope = 0
            intercept = dens.last ?? 0
        }
        let preds = dens.indices.map { intercept + slope * Double($0) }
        let residuals = zip(dens, preds).map { abs($0 - $1) }
        let mae = residuals.reduce(0, +) / Double(max(1, residuals.count))
        // ±1σ ≈ 1.25 * MAE for Laplace-ish residuals; floor at 5pp
        let half = max(0.05, mae * 1.25)
        let hits = zip(dens, preds).filter { abs($0 - $1) <= half }.count
        let total = dens.count
        let rate = total > 0 ? Double(hits) / Double(total) : 0
        let ratePP = Int((rate * 100).rounded())
        let tone: Color = ratePP >= 70 ? RTColor.optimal : (ratePP >= 50 ? RTColor.good : RTColor.warning)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "scope")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Hit rate")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(hits)/\(total) · \(ratePP)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accent.opacity(0.14))
                        .frame(height: 12)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [accent, tone],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(8, geo.size.width * CGFloat(rate)), height: 12)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)
            Text("Actuals inside ±\(Int((half * 100).rounded()))pp band")
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastHitRate)
        .accessibilityLabel("Forecast hit rate \(ratePP) percent, \(hits) of \(total)")
    }


    /// Honest #568: residual bias — signed mean residual (over/under predict) (Google Health graphics).
    @ViewBuilder
    private func densityForecastResidualBias() -> some View {
        let days = Array(history.suffix(7))
        if days.count < 4 {
            EmptyView()
        } else {
            residualBiasBody(days: days)
        }
    }

    private func residualBiasBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let xs = dens.indices.map { Double($0) }
        let sumX = xs.reduce(0, +)
        let sumY = dens.reduce(0, +)
        let sumXY = zip(xs, dens).map(*).reduce(0, +)
        let sumXX = xs.map { $0 * $0 }.reduce(0, +)
        let denom = n * sumXX - sumX * sumX
        let slope: Double
        let intercept: Double
        if abs(denom) > 1e-9 {
            slope = (n * sumXY - sumX * sumY) / denom
            intercept = (sumY - slope * sumX) / n
        } else {
            slope = 0
            intercept = dens.last ?? 0
        }
        let signed = zip(dens.indices, dens).map { i, a in a - (intercept + slope * Double(i)) }
        let bias = signed.reduce(0, +) / Double(max(1, signed.count))
        let biasPP = Int((bias * 100).rounded())
        let absPP = abs(biasPP)
        let tone: Color = absPP <= 3 ? RTColor.optimal : (absPP <= 8 ? RTColor.good : RTColor.warning)
        let verb = biasPP > 0 ? "Under" : (biasPP < 0 ? "Over" : "Neutral")
        // bias>0 ⇒ actual > predicted ⇒ model under-predicted
        let needle = max(-1.0, min(1.0, bias / 0.15)) // ±15pp full scale
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Residual bias")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(biasPP >= 0 ? "+" : "")\(biasPP)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let mid = geo.size.width / 2
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "FF375F").opacity(0.35), accent.opacity(0.12), RTColor.optimal.opacity(0.35)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 12)
                    // center tick
                    Capsule()
                        .fill(RTColor.primaryText.opacity(0.55))
                        .frame(width: 2, height: 16)
                        .offset(x: mid - 1)
                    // needle
                    Circle()
                        .fill(tone)
                        .frame(width: 14, height: 14)
                        .offset(x: mid + CGFloat(needle) * (mid - 10) - 7)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("Over-predict")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Under-predict")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityForecastBias)
        .accessibilityLabel("Residual bias \(verb) \(biasPP) percentage points")
    }




    /// Honest #538: consecutive days ending today with density ≥ 70%.
    private var densityStreak: (current: Int, best: Int, threshold: Double)? {
        let days = history.isEmpty ? [] : Array(history.suffix(30))
        guard !days.isEmpty else { return nil }
        let threshold = 0.70
        func dens(_ day: DailyHealthData) -> Double {
            let c = AirChip.all(from: day)
            guard !c.isEmpty else { return 0 }
            return Double(c.filter(\.filled).count) / Double(c.count)
        }
        var current = 0
        for day in days.reversed() {
            if dens(day) >= threshold { current += 1 } else { break }
        }
        var best = 0
        var run = 0
        for day in days {
            if dens(day) >= threshold {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
        }
        guard current > 0 || best > 0 else { return nil }
        return (current, best, threshold)
    }

    @ViewBuilder
    private var densityStreakBadge: some View {
        if let streak = densityStreak {
            let tone: Color = streak.current >= 3 ? RTColor.optimal
                : (streak.current > 0 ? accent : RTColor.secondaryText)
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    Haptic.selectionChanged()
                    showDensityStreakDetail.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .font(.caption.weight(.semibold))
                        Text("Density streak")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text("\(streak.current)d")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(tone)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tone.opacity(0.12))
                            .clipShape(Capsule())
                        Image(systemName: showDensityStreakDetail ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .foregroundStyle(accent)
                    .padding(10)
                    .background(RTColor.surfaceHighlight, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                // Honest #546: 14d calendar dots (≥ threshold = filled)
                densityStreakCalendar(threshold: streak.threshold)
                if showDensityStreakDetail {
                    HStack(spacing: 12) {
                        wowStat(title: "Now", value: "\(streak.current)d")
                        wowStat(title: "Best 30d", value: "\(streak.best)d")
                        wowStat(title: "Bar", value: "\(Int((streak.threshold * 100).rounded()))%")
                    }
                }
            }
            .accessibilityIdentifier(SurfaceID.fitbitAirDensityStreak)
            .accessibilityLabel("Density streak \(streak.current) days")
            .accessibilityAddTraits(.isButton)
        }
    }


    /// Honest #546: 14-day streak calendar dots (filled = density ≥ threshold).
    private func densityStreakCalendar(threshold: Double) -> some View {
        let days = Array(history.suffix(14))
        return HStack(spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                let chips = AirChip.all(from: day)
                let dens = chips.isEmpty ? 0.0 : Double(chips.filter(\.filled).count) / Double(chips.count)
                let hit = dens >= threshold
                Circle()
                    .fill(hit ? RTColor.optimal.opacity(0.9) : RTColor.divider)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle().stroke(hit ? RTColor.optimal : RTColor.tertiaryText.opacity(0.35), lineWidth: 0.5)
                    )
                    .accessibilityLabel(hit ? "Above bar" : "Below bar")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityStreakCal)
        .accessibilityLabel("Density streak calendar, last \(days.count) days")
    }

    /// Honest #527: last-7d mean density vs prior-7d.
    private var densityWow: (current: Double, prior: Double, deltaPP: Double)? {
        guard history.count >= 8 else { return nil }
        let currentDays = Array(history.suffix(7))
        let priorDays = Array(history.dropLast(min(7, history.count)).suffix(7))
        guard priorDays.count >= 3 else { return nil }
        func meanDensity(_ days: [DailyHealthData]) -> Double {
            let vals = days.map { day -> Double in
                let c = AirChip.all(from: day)
                guard !c.isEmpty else { return 0 }
                return Double(c.filter(\.filled).count) / Double(c.count)
            }
            guard !vals.isEmpty else { return 0 }
            return vals.reduce(0, +) / Double(vals.count)
        }
        let cur = meanDensity(currentDays)
        let prior = meanDensity(priorDays)
        return (cur, prior, (cur - prior) * 100)
    }

    @ViewBuilder
    private var densityWowBadge: some View {
        if let wow = densityWow {
            let sign = wow.deltaPP >= 0 ? "+" : ""
            let tone: Color = abs(wow.deltaPP) < 0.5 ? RTColor.secondaryText
                : (wow.deltaPP > 0 ? RTColor.optimal : RTColor.warning)
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    Haptic.selectionChanged()
                    showDensityWowDetail.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.caption.weight(.semibold))
                        Text("WoW density")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text("\(sign)\(Int(wow.deltaPP.rounded()))pp")
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(tone)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(tone.opacity(0.12))
                            .clipShape(Capsule())
                        Image(systemName: showDensityWowDetail ? "chevron.up" : "chevron.down")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .foregroundStyle(accent)
                    .padding(10)
                    .background(RTColor.surfaceHighlight, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                if showDensityWowDetail {
                    HStack(spacing: 12) {
                        wowStat(title: "This 7d", value: "\(Int((wow.current * 100).rounded()))%")
                        wowStat(title: "Prior 7d", value: "\(Int((wow.prior * 100).rounded()))%")
                        wowStat(title: "Δ", value: "\(sign)\(String(format: "%.1f", wow.deltaPP))pp")
                    }
                }
            }
            .accessibilityIdentifier(SurfaceID.fitbitAirDensityWow)
            .accessibilityLabel("Week over week density \(sign)\(Int(wow.deltaPP.rounded())) percentage points")
            .accessibilityAddTraits(.isButton)
        }
    }

    private func wowStat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(RTColor.tertiaryText)
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(RTColor.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RTColor.surfaceHighlight.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
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
        let densMean: Double = {
            let vals = points.map(\.density).filter { $0 > 0 }
            guard !vals.isEmpty else { return 0 }
            return vals.reduce(0, +) / Double(vals.count)
        }()
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Density · \(sparkPeriod)d")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                if densMean > 0 {
                    Text("avg \(Int((densMean * 100).rounded()))%")
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(RTColor.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RTColor.secondaryText.opacity(0.10))
                        .clipShape(Capsule())
                        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySparkMean)
                        .accessibilityLabel("Density spark mean \(Int((densMean * 100).rounded())) percent")
                }
                if let idx = sparkScrubIndex ?? (points.isEmpty ? nil : points.count - 1),
                   points.indices.contains(idx) {
                    let scrub = points[idx].density
                    Text("\(Int((scrub * 100).rounded()))%")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(accent)
                    if densMean > 0 {
                        let dpp = (scrub - densMean) * 100
                        let sign = dpp >= 0 ? "+" : ""
                        Text("\(sign)\(Int(dpp.rounded()))pp")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(abs(dpp) < 3 ? RTColor.secondaryText : (dpp >= 0 ? RTColor.optimal : RTColor.warning))
                    }
                }
            }
            // Honest #548: density spark min–max range strip
            if let densMin = points.map(\.density).min(),
               let densMax = points.map(\.density).max(),
               densMax > 0 {
                let scrubD: Double = {
                    if let idx = sparkScrubIndex ?? (points.isEmpty ? nil : points.count - 1),
                       points.indices.contains(idx) {
                        return points[idx].density
                    }
                    return densMax
                }()
                HStack(spacing: 8) {
                    Text("\(Int((densMin * 100).rounded()))–\(Int((densMax * 100).rounded()))%")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(RTColor.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(RTColor.secondaryText.opacity(0.10))
                        .clipShape(Capsule())
                        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySparkRange)
                        .accessibilityLabel("Density spark range")
                    GeometryReader { geo in
                        let span = max(densMax - densMin, 0.0001)
                        let scrubFrac = CGFloat((scrubD - densMin) / span)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(accent.opacity(0.18))
                                .frame(height: 6)
                            Capsule()
                                .fill(accent)
                                .frame(width: max(6, geo.size.width * 0.08), height: 6)
                                .offset(x: max(0, min(geo.size.width - 6, geo.size.width * scrubFrac - 3)))
                        }
                        .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .frame(height: 14)
                    Text("range")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                .accessibilityElement(children: .contain)
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
                    // Honest #556: mean density rule across spark window
                    if densMean > 0 {
                        RuleMark(y: .value("Mean", densMean))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.55))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
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


    /// Honest #570: density distribution histogram — last-14 day density bins (Google Health graphics).
    @ViewBuilder
    private var densityDistributionHist: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityHistBody(days: days)
        }
    }

    private func densityHistBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        struct Bin: Identifiable {
            let id: Int
            let label: String
            let count: Int
        }
        let edges = [0.0, 0.25, 0.5, 0.75, 1.01]
        let labels = ["0–24", "25–49", "50–74", "75–100"]
        var bins: [Bin] = []
        for i in 0..<4 {
            let cnt = dens.filter { $0 >= edges[i] && $0 < edges[i + 1] }.count
            bins.append(Bin(id: i, label: labels[i], count: cnt))
        }
        let peak = bins.map(\.count).max() ?? 0
        let meanPP = Int(((dens.reduce(0, +) / Double(max(1, dens.count))) * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density hist")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("μ \(meanPP)% · \(dens.count)d")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.12))
                    .clipShape(Capsule())
            }
            Chart {
                ForEach(bins) { bin in
                    BarMark(
                        x: .value("Bin", bin.label),
                        y: .value("Days", bin.count)
                    )
                    .foregroundStyle(accent.opacity(0.35 + 0.2 * Double(bin.id)))
                    .cornerRadius(4)
                }
            }
            .chartYScale(domain: 0...(max(1, peak)))
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(RTColor.divider)
                    AxisValueLabel()
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(RTColor.secondaryText)
                        .font(.caption2)
                }
            }
            .frame(height: 88)
            Text("Days in each density band · last \(dens.count)")
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityHist)
        .accessibilityLabel("Density histogram mean \(meanPP) percent")
    }


    /// Honest #572: density CV meter — 14d coefficient of variation (Google Health graphics).
    @ViewBuilder
    private var densityCVMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityCVBody(days: days)
        }
    }

    private func densityCVBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let variance = dens.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / n
        let sd = variance.squareRoot()
        let cv = mean > 1e-6 ? sd / mean : 0
        let cvPP = Int((cv * 100).rounded())
        let tone: Color = cvPP <= 15 ? RTColor.optimal : (cvPP <= 30 ? RTColor.good : RTColor.warning)
        let stability = cvPP <= 15 ? "Stable" : (cvPP <= 30 ? "Mixed" : "Volatile")
        let barFrac = min(1.0, cv / 0.5) // 50% CV = full bar
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density CV")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(stability) · \(cvPP)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.14)).frame(height: 12)
                    Capsule()
                        .fill(LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * CGFloat(barFrac)), height: 12)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)
            Text("σ/μ over last \(dens.count)d · lower is steadier air coverage")
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityCV)
        .accessibilityLabel("Density coefficient of variation \(cvPP) percent, \(stability)")
    }


    /// Honest #574: density skew meter — Pearson moment skewness of last-14 dens (Google Health graphics).
    @ViewBuilder
    private var densitySkewMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densitySkewBody(days: days)
        }
    }

    private func densitySkewBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let m2 = dens.map { let d = $0 - mean; return d * d }.reduce(0, +) / n
        let m3 = dens.map { let d = $0 - mean; return d * d * d }.reduce(0, +) / n
        let sd = m2.squareRoot()
        let skew = sd > 1e-9 ? m3 / (sd * sd * sd) : 0
        let skewPP = Int((skew * 100).rounded()) // ×100 for display
        let absS = abs(skew)
        let tone: Color = absS <= 0.5 ? RTColor.optimal : (absS <= 1.0 ? RTColor.good : RTColor.warning)
        let verb = skew > 0.15 ? "Right" : (skew < -0.15 ? "Left" : "Sym")
        let needle = max(-1.0, min(1.0, skew / 2.0))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "triangle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density skew")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(skew >= 0 ? "+" : "")\(String(format: "%.2f", skew))")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let mid = geo.size.width / 2
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "FF375F").opacity(0.3), accent.opacity(0.12), RTColor.optimal.opacity(0.35)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 12)
                    Capsule().fill(RTColor.primaryText.opacity(0.55)).frame(width: 2, height: 16).offset(x: mid - 1)
                    Circle().fill(tone).frame(width: 14, height: 14)
                        .offset(x: mid + CGFloat(needle) * (mid - 10) - 7)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("Left tail")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Right tail")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySkew)
        .accessibilityLabel("Density skew \(verb) \(String(format: "%.2f", skew))")
    }




    /// Honest #576: density IQR band — Q1–Q3 + median of last-14 dens (Google Health graphics).
    @ViewBuilder
    private var densityIQRMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityIQRBody(days: days)
        }
    }

    private func densityIQRBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }.sorted()
        let n = dens.count
        func pct(_ p: Double) -> Double {
            let i = p * Double(n - 1)
            let lo = Int(i.rounded(.down))
            let hi = min(n - 1, lo + 1)
            let f = i - Double(lo)
            return dens[lo] * (1 - f) + dens[hi] * f
        }
        let q1 = pct(0.25)
        let med = pct(0.50)
        let q3 = pct(0.75)
        let iqr = q3 - q1
        let iqrPP = Int((iqr * 100).rounded())
        let medPP = Int((med * 100).rounded())
        let tone: Color = iqrPP <= 12 ? RTColor.optimal : (iqrPP <= 22 ? RTColor.good : RTColor.warning)
        let verb = iqrPP <= 12 ? "Tight" : (iqrPP <= 22 ? "Steady" : "Wide")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.split.3x1.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density IQR")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(iqrPP)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let x1 = CGFloat(q1) * w
                let x3 = CGFloat(q3) * w
                let xm = CGFloat(med) * w
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accent.opacity(0.12))
                        .frame(height: 12)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [tone.opacity(0.35), tone.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(4, x3 - x1), height: 12)
                        .offset(x: x1)
                    Capsule()
                        .fill(RTColor.primaryText.opacity(0.85))
                        .frame(width: 3, height: 18)
                        .offset(x: max(0, xm - 1.5))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("Q1 \(Int((q1 * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Med \(medPP)%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("Q3 \(Int((q3 * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityIQR)
        .accessibilityLabel("Density IQR \(verb) \(iqrPP) points, median \(medPP) percent")
    }



    /// Honest #578: density percentile rank — tonight dens vs last-14 (Google Health graphics).
    @ViewBuilder
    private var densityPercentileMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityPercentileBody(days: days)
        }
    }

    private func densityPercentileBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let today = dens.last ?? density
        let sorted = dens.sorted()
        let below = sorted.filter { $0 < today }.count
        let equal = sorted.filter { $0 == today }.count
        // Mid-rank percentile
        let pct = (Double(below) + 0.5 * Double(equal)) / Double(sorted.count)
        let pctPP = Int((pct * 100).rounded())
        let todayPP = Int((today * 100).rounded())
        let tone: Color = pctPP >= 70 ? RTColor.optimal : (pctPP >= 40 ? RTColor.good : RTColor.warning)
        let verb = pctPP >= 70 ? "High" : (pctPP >= 40 ? "Mid" : "Low")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "percent")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density percentile")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) P\(pctPP)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let x = CGFloat(pct) * w
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(hex: "FF375F").opacity(0.35), RTColor.good.opacity(0.45), RTColor.optimal.opacity(0.55)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 12)
                    // tonight marker
                    Circle()
                        .fill(tone)
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .frame(width: 16, height: 16)
                        .offset(x: max(0, min(w - 16, x - 8)))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("P0")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Tonight \(todayPP)% · P\(pctPP) of \(sorted.count)d")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("P100")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityPercentile)
        .accessibilityLabel("Density percentile \(verb) P\(pctPP), tonight \(todayPP) percent")
    }



    /// Honest #580: density envelope chart — dens spark with Q1–Q3 band (Google Health graphics).
    @ViewBuilder
    private var densityEnvelopeChart: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityEnvelopeBody(days: days)
        }
    }

    private func densityEnvelopeBody(days: [DailyHealthData]) -> some View {
        struct Pt: Identifiable {
            let id: Int
            let date: Date
            let dens: Double
        }
        let pts: [Pt] = days.enumerated().map { i, day in
            let chips = AirChip.all(from: day)
            let dens = chips.isEmpty ? 0.0 : Double(chips.filter(\.filled).count) / Double(chips.count)
            return Pt(id: i, date: day.date, dens: dens)
        }
        let sorted = pts.map(\.dens).sorted()
        let n = sorted.count
        func pct(_ p: Double) -> Double {
            let i = p * Double(n - 1)
            let lo = Int(i.rounded(.down))
            let hi = min(n - 1, lo + 1)
            let f = i - Double(lo)
            return sorted[lo] * (1 - f) + sorted[hi] * f
        }
        let q1 = pct(0.25)
        let med = pct(0.50)
        let q3 = pct(0.75)
        let iqrPP = Int(((q3 - q1) * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density envelope")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("IQR \(iqrPP)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accent.opacity(0.12))
                    .clipShape(Capsule())
            }
            Chart {
                ForEach(pts) { pt in
                    AreaMark(
                        x: .value("Day", pt.date),
                        yStart: .value("Q1", q1),
                        yEnd: .value("Q3", q3)
                    )
                    .foregroundStyle(accent.opacity(0.14))
                    LineMark(
                        x: .value("Day", pt.date),
                        y: .value("Density", pt.dens)
                    )
                    .foregroundStyle(accent)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                RuleMark(y: .value("Med", med))
                    .foregroundStyle(RTColor.optimal.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            .chartYScale(domain: 0...1)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 0.5, 1]) { v in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(RTColor.divider)
                    AxisValueLabel {
                        if let d = v.as(Double.self) {
                            Text("\(Int((d * 100).rounded()))%")
                                .font(.caption2)
                                .foregroundStyle(RTColor.tertiaryText)
                        }
                    }
                }
            }
            .frame(height: 88)
            HStack {
                Text("Q1 \(Int((q1 * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Med \(Int((med * 100).rounded()))%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.optimal)
                Spacer()
                Text("Q3 \(Int((q3 * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityEnvelope)
        .accessibilityLabel("Density envelope IQR \(iqrPP) points")
    }



    /// Honest #582: density MAD meter — median absolute deviation of last-14 dens (Google Health graphics).
    @ViewBuilder
    private var densityMADMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityMADBody(days: days)
        }
    }

    private func densityMADBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }.sorted()
        let n = dens.count
        let mid = n / 2
        let median: Double = n % 2 == 0 ? (dens[mid - 1] + dens[mid]) / 2 : dens[mid]
        let absDev = dens.map { abs($0 - median) }.sorted()
        let mad: Double = n % 2 == 0 ? (absDev[mid - 1] + absDev[mid]) / 2 : absDev[mid]
        let madPP = Int((mad * 100).rounded())
        let medPP = Int((median * 100).rounded())
        let tone: Color = madPP <= 8 ? RTColor.optimal : (madPP <= 15 ? RTColor.good : RTColor.warning)
        let verb = madPP <= 8 ? "Stable" : (madPP <= 15 ? "Mild" : "Volatile")
        let needle = min(1.0, mad / 0.30) // 30pp MAD = full scale
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density MAD")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(madPP)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [RTColor.optimal.opacity(0.4), RTColor.good.opacity(0.4), Color(hex: "FF375F").opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 12)
                    Circle()
                        .fill(tone)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(w - 14, CGFloat(needle) * w - 7)))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("Med \(medPP)%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("robust scale · last \(n)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityMAD)
        .accessibilityLabel("Density MAD \(verb) \(madPP) points")
    }

    /// Honest #584: density Tukey fences — box + 1.5×IQR whiskers + outlier ticks (Google Health graphics).
    @ViewBuilder
    private var densityTukeyFences: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityTukeyBody(days: days)
        }
    }

    private func densityTukeyBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let sorted = dens.sorted()
        let n = sorted.count
        func pct(_ p: Double) -> Double {
            let i = p * Double(n - 1)
            let lo = Int(i.rounded(.down))
            let hi = min(n - 1, lo + 1)
            let f = i - Double(lo)
            return sorted[lo] * (1 - f) + sorted[hi] * f
        }
        let q1 = pct(0.25)
        let med = pct(0.50)
        let q3 = pct(0.75)
        let iqr = max(q3 - q1, 0.0001)
        let loFence = max(0.0, q1 - 1.5 * iqr)
        let hiFence = min(1.0, q3 + 1.5 * iqr)
        let outliers = dens.filter { $0 < loFence || $0 > hiFence }
        let outN = outliers.count
        let tone: Color = outN == 0 ? RTColor.optimal : (outN <= 2 ? RTColor.good : RTColor.warning)
        let verb = outN == 0 ? "Clean" : (outN == 1 ? "1 outlier" : "\(outN) outliers")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.boxplot.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density fences")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text(verb)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let xLo = CGFloat(loFence) * w
                let xHi = CGFloat(hiFence) * w
                let x1 = CGFloat(q1) * w
                let x3 = CGFloat(q3) * w
                let xm = CGFloat(med) * w
                ZStack(alignment: .leading) {
                    // track
                    Capsule()
                        .fill(accent.opacity(0.10))
                        .frame(height: 10)
                    // whisker span
                    Capsule()
                        .fill(tone.opacity(0.28))
                        .frame(width: max(4, xHi - xLo), height: 4)
                        .offset(x: xLo, y: 0)
                    // fence end caps
                    Capsule().fill(tone.opacity(0.7)).frame(width: 2, height: 14).offset(x: max(0, xLo - 1))
                    Capsule().fill(tone.opacity(0.7)).frame(width: 2, height: 14).offset(x: max(0, min(w - 2, xHi - 1)))
                    // IQR box
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(LinearGradient(
                            colors: [tone.opacity(0.35), tone.opacity(0.65)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(width: max(6, x3 - x1), height: 14)
                        .offset(x: x1)
                    // median
                    Capsule()
                        .fill(RTColor.primaryText.opacity(0.9))
                        .frame(width: 3, height: 18)
                        .offset(x: max(0, xm - 1.5))
                    // outlier ticks
                    ForEach(Array(outliers.enumerated()), id: \.offset) { _, v in
                        Circle()
                            .fill(Color(hex: "FF375F"))
                            .frame(width: 7, height: 7)
                            .offset(x: max(0, min(w - 7, CGFloat(v) * w - 3.5)))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 20)
            HStack {
                Text("Lo \(Int((loFence * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Med \(Int((med * 100).rounded()))%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("Hi \(Int((hiFence * 100).rounded()))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityTukey)
        .accessibilityLabel("Density Tukey fences \(verb), median \(Int((med * 100).rounded())) percent")
    }

    /// Honest #586: density slope meter — 14d dens trend line + rising/stable/falling (Google Health graphics).
    @ViewBuilder
    private var densitySlopeMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densitySlopeBody(days: days)
        }
    }

    private func densitySlopeBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = dens.count
        let xs = (0..<n).map { Double($0) }
        let meanX = xs.reduce(0, +) / Double(n)
        let meanY = dens.reduce(0, +) / Double(n)
        var num = 0.0, den = 0.0
        for i in 0..<n {
            let dx = xs[i] - meanX
            num += dx * (dens[i] - meanY)
            den += dx * dx
        }
        let slope = den > 0 ? num / den : 0 // dens units per day
        let slopePP = slope * 100 // percentage points / day
        let slopePP7 = slopePP * 7 // weekly
        let absPP = abs(slopePP)
        let verb: String
        let tone: Color
        if absPP < 0.4 {
            verb = "Stable"
            tone = RTColor.optimal
        } else if slopePP > 0 {
            verb = "Rising"
            tone = RTColor.good
        } else {
            verb = "Falling"
            tone = Color(hex: "FF375F")
        }
        let endY = meanY + slope * (Double(n - 1) - meanX)
        let startY = meanY + slope * (0 - meanX)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density slope")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(slopePP7 >= 0 ? "+" : "")\(String(format: "%.1f", slopePP7))pp/wk")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let minV = min(dens.min() ?? 0, min(startY, endY))
                let maxV = max(dens.max() ?? 1, max(startY, endY))
                let span = max(0.05, maxV - minV)
                ZStack {
                    // dens spark
                    Path { path in
                        for (i, v) in dens.enumerated() {
                            let x = CGFloat(i) / CGFloat(max(1, n - 1)) * w
                            let y = h - CGFloat((v - minV) / span) * h
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(accent.opacity(0.55), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    // trend line
                    Path { path in
                        let y0 = h - CGFloat((startY - minV) / span) * h
                        let y1 = h - CGFloat((endY - minV) / span) * h
                        path.move(to: CGPoint(x: 0, y: y0))
                        path.addLine(to: CGPoint(x: w, y: y1))
                    }
                    .stroke(tone, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                }
            }
            .frame(height: 36)
            HStack {
                Text("n=\(n)d")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text(String(format: "%+.2f pp/d", slopePP))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tone)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySlope)
        .accessibilityLabel("Density slope \(verb) \(String(format: "%.1f", slopePP7)) points per week")
    }


    /// Honest #588: density z-score strip — tonight dens vs last-14 μ/σ (Google Health graphics).
    @ViewBuilder
    private var densityZScoreStrip: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityZScoreBody(days: days)
        }
    }

    private func densityZScoreBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let var_ = dens.map { let d = $0 - mean; return d * d }.reduce(0, +) / max(n - 1, 1)
        let sd = max(var_.squareRoot(), 0.0001)
        let tonight = dens.last ?? mean
        let z = (tonight - mean) / sd
        let zClamped = max(-3.0, min(3.0, z))
        let zDisp = String(format: "%+.1fσ", z)
        let tone: Color = abs(z) < 0.75 ? RTColor.optimal : (abs(z) < 1.5 ? RTColor.good : RTColor.warning)
        let verb: String = {
            if z >= 1.5 { return "Hot" }
            if z >= 0.75 { return "High" }
            if z <= -1.5 { return "Cold" }
            if z <= -0.75 { return "Low" }
            return "Typical"
        }()
        let needle = (zClamped + 3.0) / 6.0
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density z-score")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(zDisp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [
                                Color(hex: "FF375F").opacity(0.35),
                                RTColor.good.opacity(0.35),
                                RTColor.optimal.opacity(0.45),
                                RTColor.good.opacity(0.35),
                                Color(hex: "FF375F").opacity(0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 12)
                    // mean tick at center
                    Capsule().fill(RTColor.primaryText.opacity(0.55))
                        .frame(width: 2, height: 16)
                        .offset(x: w * 0.5 - 1)
                    Circle()
                        .fill(tone)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(w - 14, CGFloat(needle) * w - 7)))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("−3σ")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("μ \(Int((mean * 100).rounded()))%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("+3σ")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityZScore)
        .accessibilityLabel("Density z-score \(verb) \(zDisp)")
    }


    /// Honest #590: density ACF meter — lag-1 autocorrelation of last-14 dens (Google Health graphics).
    @ViewBuilder
    private var densityACFMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 6 {
            EmptyView()
        } else {
            densityACFBody(days: days)
        }
    }

    private func densityACFBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = dens.count
        let mean = dens.reduce(0, +) / Double(n)
        var num = 0.0, den = 0.0
        for i in 0..<(n - 1) {
            num += (dens[i] - mean) * (dens[i + 1] - mean)
        }
        for v in dens {
            let d = v - mean
            den += d * d
        }
        let acf = den > 0 ? num / den : 0
        let acfClamped = max(-1.0, min(1.0, acf))
        let tone: Color = abs(acf) >= 0.5 ? RTColor.optimal : (abs(acf) >= 0.2 ? RTColor.good : RTColor.warning)
        let verb: String = {
            if acf >= 0.5 { return "Sticky" }
            if acf >= 0.2 { return "Mild" }
            if acf <= -0.2 { return "Flip" }
            return "Noise"
        }()
        let needle = (acfClamped + 1.0) / 2.0 // -1…+1 → 0…1
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density ACF₁")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(String(format: "%+.2f", acf))")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [
                                Color(hex: "FF375F").opacity(0.35),
                                RTColor.warning.opacity(0.35),
                                RTColor.optimal.opacity(0.45),
                                RTColor.good.opacity(0.35),
                                accent.opacity(0.45)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 12)
                    // zero tick
                    Capsule().fill(RTColor.primaryText.opacity(0.55))
                        .frame(width: 2, height: 16)
                        .offset(x: w * 0.5 - 1)
                    Circle()
                        .fill(tone)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(w - 14, CGFloat(needle) * w - 7)))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("−1")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("lag-1 · last \(n)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("+1")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityACF)
        .accessibilityLabel("Density autocorrelation \(verb) \(String(format: "%.2f", acf))")
    }


    /// Honest #592: density entropy meter — Shannon entropy of dens histogram (Google Health graphics).
    @ViewBuilder
    private var densityEntropyMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityEntropyBody(days: days)
        }
    }

    private func densityEntropyBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        // 5 equal bins over 0…1
        var bins = Array(repeating: 0, count: 5)
        for v in dens {
            let i = min(4, max(0, Int((v * 5.0).rounded(.down))))
            bins[i] += 1
        }
        let n = Double(dens.count)
        var h = 0.0
        for c in bins where c > 0 {
            let p = Double(c) / n
            h -= p * Foundation.log2(p)
        }
        // max entropy for 5 bins = log2(5) ≈ 2.32
        let hMax = Foundation.log2(5.0)
        let hNorm = h / hMax
        let hDisp = String(format: "%.2f", h)
        let tone: Color = hNorm <= 0.45 ? RTColor.optimal : (hNorm <= 0.75 ? RTColor.good : RTColor.warning)
        let verb = hNorm <= 0.45 ? "Focused" : (hNorm <= 0.75 ? "Mixed" : "Scattered")
        let needle = min(1.0, hNorm)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density entropy")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) H=\(hDisp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(bins.enumerated()), id: \.offset) { _, c in
                        let frac = CGFloat(c) / CGFloat(max(1, dens.count))
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(tone.opacity(0.35 + 0.5 * Double(frac)))
                            .frame(width: max(8, (w - 12) / 5), height: max(4, 28 * frac))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 32)
            .overlay(alignment: .trailing) {
                // entropy needle strip on right edge
                EmptyView()
            }
            HStack {
                Text("5 bins · last \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("\(Int((hNorm * 100).rounded()))% of max")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(tone)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityEntropy)
        .accessibilityLabel("Density entropy \(verb) \(hDisp)")
    }



    /// Honest #594: density kurtosis meter — excess kurtosis of dens series (Google Health graphics).
    @ViewBuilder
    private var densityKurtosisMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityKurtosisBody(days: days)
        }
    }

    private func densityKurtosisBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let m2 = dens.map { pow($0 - mean, 2) }.reduce(0, +) / n
        let m4 = dens.map { pow($0 - mean, 4) }.reduce(0, +) / n
        let kurt = m2 > 1e-9 ? (m4 / (m2 * m2)) - 3.0 : 0.0  // excess kurtosis
        let verb: String
        let tone: Color
        if kurt >= 1.0 {
            verb = "Spiky"; tone = RTColor.warning
        } else if kurt <= -0.5 {
            verb = "Flat"; tone = RTColor.good
        } else {
            verb = "Normal"; tone = RTColor.optimal
        }
        let kDisp = String(format: "%+.2f", kurt)
        // needle mapped: clamp kurt into [-2, 3] → 0…1
        let needle = min(1.0, max(0.0, (kurt + 2.0) / 5.0))
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density kurtosis")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) κ=\(kDisp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [RTColor.good.opacity(0.35), RTColor.optimal.opacity(0.35), RTColor.warning.opacity(0.45)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(height: 10)
                    // zero marker at (-0 relative) → (2/5)
                    Capsule()
                        .fill(RTColor.primaryText.opacity(0.35))
                        .frame(width: 2, height: 14)
                        .offset(x: w * (2.0 / 5.0) - 1)
                    Circle()
                        .fill(tone)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .offset(x: w * needle - 7)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("excess κ · last \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("flat ← → spiky")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityKurtosis)
        .accessibilityLabel("Density kurtosis \(verb) \(kDisp)")
    }




    /// Honest #596: density span meter — max−min air-fill over window (Fitbit/Google Health graphics).
    @ViewBuilder
    private var densitySpanMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densitySpanBody(days: days)
        }
    }

    private func densitySpanBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let lo = dens.min() ?? 0
        let hi = dens.max() ?? 0
        let span = hi - lo
        let mean = dens.reduce(0, +) / Double(dens.count)
        let verb: String
        let tone: Color
        if span <= 0.12 {
            verb = "Steady"; tone = RTColor.optimal
        } else if span <= 0.28 {
            verb = "Mixed"; tone = RTColor.good
        } else {
            verb = "Swingy"; tone = RTColor.warning
        }
        let spanPct = Int((span * 100).rounded())
        let loPct = Int((lo * 100).rounded())
        let hiPct = Int((hi * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.and.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density span")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) Δ\(spanPct)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(RTColor.tertiaryText.opacity(0.12))
                        .frame(height: 10)
                    // filled band from lo…hi
                    Capsule()
                        .fill(LinearGradient(
                            colors: [accent.opacity(0.45), tone],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, w * span), height: 10)
                        .offset(x: w * lo)
                    // mean tick
                    Capsule()
                        .fill(RTColor.primaryText.opacity(0.55))
                        .frame(width: 2, height: 16)
                        .offset(x: w * mean - 1)
                    // lo / hi dots
                    Circle()
                        .fill(accent)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .offset(x: w * lo - 6)
                    Circle()
                        .fill(tone)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 1.5))
                        .offset(x: w * hi - 6)
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 18)
            HStack {
                Text("lo \(loPct)%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("mean \(Int((mean * 100).rounded()))% · last \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("hi \(hiPct)%")
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySpan)
        .accessibilityLabel("Density span \(verb) \(spanPct) percent")
    }



    /// Honest #598: density Gini meter — inequality of daily air-fill (Fitbit/Google Health graphics).
    @ViewBuilder
    private var densityGiniMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityGiniBody(days: days)
        }
    }

    private func densityGiniBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let sorted = dens.sorted()
        let n = Double(sorted.count)
        let sum = sorted.reduce(0, +)
        // Gini = (2 * Σ i*x_i) / (n * Σ x_i) - (n+1)/n
        var gini = 0.0
        if sum > 1e-9 {
            var weighted = 0.0
            for (i, x) in sorted.enumerated() {
                weighted += Double(i + 1) * x
            }
            gini = (2.0 * weighted) / (n * sum) - (n + 1.0) / n
            gini = max(0, min(1, gini))
        }
        let verb: String
        let tone: Color
        if gini <= 0.15 {
            verb = "Even"; tone = RTColor.optimal
        } else if gini <= 0.35 {
            verb = "Mild"; tone = RTColor.good
        } else {
            verb = "Uneven"; tone = RTColor.warning
        }
        let gDisp = String(format: "%.2f", gini)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density Gini")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) G=\(gDisp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // Lorenz-ish polyline + equality diagonal
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    path.addLine(to: CGPoint(x: w, y: 0))
                }
                .stroke(RTColor.tertiaryText.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h))
                    var cum = 0.0
                    let total = max(sum, 1e-9)
                    for (i, x) in sorted.enumerated() {
                        cum += x
                        let px = w * Double(i + 1) / n
                        let py = h * (1.0 - cum / total)
                        path.addLine(to: CGPoint(x: px, y: py))
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
                // Gini needle on bottom track
                Capsule()
                    .fill(RTColor.tertiaryText.opacity(0.12))
                    .frame(height: 6)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                Capsule()
                    .fill(tone)
                    .frame(width: max(4, w * gini), height: 6)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 56)
            HStack {
                Text("even ← → uneven · last \(sorted.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("Lorenz vs equality")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityGini)
        .accessibilityLabel("Density Gini \(verb) \(gDisp)")
    }



    /// Honest #600: density volatility meter — σ of day-to-day air-fill diffs (Fitbit/Google Health graphics).
    @ViewBuilder
    private var densityVolatilityMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 6 {
            EmptyView()
        } else {
            densityVolatilityBody(days: days)
        }
    }

    private func densityVolatilityBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var diffs: [Double] = []
        for i in 1..<dens.count {
            diffs.append(dens[i] - dens[i - 1])
        }
        let n = Double(diffs.count)
        let mean = diffs.reduce(0, +) / n
        let variance = diffs.map { pow($0 - mean, 2) }.reduce(0, +) / n
        let sigma = sqrt(variance)
        let verb: String
        let tone: Color
        if sigma <= 0.06 {
            verb = "Calm"; tone = RTColor.optimal
        } else if sigma <= 0.14 {
            verb = "Choppy"; tone = RTColor.good
        } else {
            verb = "Volatile"; tone = RTColor.warning
        }
        let sDisp = String(format: "%.0f", sigma * 100)
        let maxAbs = max(diffs.map { abs($0) }.max() ?? 0.01, 0.01)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density volatility")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) σ=\(sDisp)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let midY = h / 2
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: w, y: midY))
                }
                .stroke(RTColor.tertiaryText.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                Path { path in
                    for (i, d) in diffs.enumerated() {
                        let x = w * (Double(i) + 0.5) / Double(diffs.count)
                        let y = midY - CGFloat(d / maxAbs) * (h * 0.42)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                // σ band
                Capsule()
                    .fill(tone.opacity(0.18))
                    .frame(height: max(4, h * CGFloat(min(1, sigma / maxAbs)) * 0.84))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 44)
            HStack {
                Text("Δ dens · last \(diffs.count) steps")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("calm ← → volatile")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityVolatility)
        .accessibilityLabel("Density volatility \(verb) \(sDisp) percentage points")
    }



    /// Honest #602: density outlier days — count beyond Tukey fences (Fitbit/Google Health graphics).
    @ViewBuilder
    private var densityOutlierMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 6 {
            EmptyView()
        } else {
            densityOutlierBody(days: days)
        }
    }

    private func densityOutlierBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let sorted = dens.sorted()
        let n = sorted.count
        let q1 = sorted[max(0, n / 4)]
        let q3 = sorted[min(n - 1, (3 * n) / 4)]
        let iqr = max(q3 - q1, 1e-9)
        let lo = q1 - 1.5 * iqr
        let hi = q3 + 1.5 * iqr
        let flags = dens.map { $0 < lo || $0 > hi }
        let count = flags.filter { $0 }.count
        let verb: String
        let tone: Color
        if count == 0 {
            verb = "Clean"; tone = RTColor.optimal
        } else if count <= 2 {
            verb = "Few"; tone = RTColor.good
        } else {
            verb = "Many"; tone = RTColor.warning
        }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density outliers")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(count)/\(n)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let step = w / CGFloat(max(1, dens.count))
                ZStack(alignment: .bottomLeading) {
                    // fence band
                    let yLo = h * (1 - CGFloat(max(0, min(1, lo))))
                    let yHi = h * (1 - CGFloat(max(0, min(1, hi))))
                    Rectangle()
                        .fill(accent.opacity(0.08))
                        .frame(height: max(2, yLo - yHi))
                        .offset(y: yHi)
                    ForEach(Array(dens.enumerated()), id: \.offset) { i, d in
                        let x = step * CGFloat(i) + step * 0.25
                        let y = h * (1 - CGFloat(max(0, min(1, d))))
                        Circle()
                            .fill(flags[i] ? tone : accent.opacity(0.55))
                            .frame(width: flags[i] ? 10 : 7, height: flags[i] ? 10 : 7)
                            .position(x: x + 3.5, y: y)
                    }
                }
            }
            .frame(height: 48)
            HStack {
                Text(String(format: "fences %.0f–%.0f%% · Tukey 1.5×IQR", lo * 100, hi * 100))
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("last \(n)d")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityOutliers)
        .accessibilityLabel("Density outliers \(verb) \(count) of \(n)")
    }



    /// Honest #604: density HHI — Herfindahl concentration of category fill (Fitbit/Google Health graphics).
    @ViewBuilder
    private var densityHHIMeter: some View {
        let chips = AirChip.all(from: history.last ?? data)
        if chips.isEmpty {
            EmptyView()
        } else {
            densityHHIBody(chips: chips)
        }
    }

    private func densityHHIBody(chips: [AirChip]) -> some View {
        let cats = AirDensityCategory.allCases
        let fills: [Double] = cats.map { cat in
            let n = max(1, chips.filter { cat.chipIDs.contains($0.id) }.count)
            return Double(chips.filter { cat.chipIDs.contains($0.id) && $0.filled }.count) / Double(n)
        }
        let sum = fills.reduce(0, +)
        let shares: [Double] = sum > 1e-9 ? fills.map { $0 / sum } : Array(repeating: 1.0 / Double(cats.count), count: cats.count)
        let hhi = shares.map { $0 * $0 }.reduce(0, +)  // 1/3…1
        // normalize to 0…1 vs equal (1/3)
        let equal = 1.0 / Double(cats.count)
        let span = max(1e-9, 1.0 - equal)
        let conc = max(0, min(1, (hhi - equal) / span))
        let verb: String
        let tone: Color
        if conc <= 0.2 {
            verb = "Diffuse"; tone = RTColor.optimal
        } else if conc <= 0.5 {
            verb = "Focused"; tone = RTColor.good
        } else {
            verb = "Narrow"; tone = RTColor.warning
        }
        let hDisp = String(format: "%.2f", hhi)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density HHI")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(hDisp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                HStack(spacing: 3) {
                    ForEach(Array(cats.enumerated()), id: \.element.id) { idx, cat in
                        let frac = CGFloat(shares[idx])
                        VStack(spacing: 4) {
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [cat.color.opacity(0.45), cat.color],
                                    startPoint: .bottom, endPoint: .top))
                                .frame(width: max(8, (w - 12) / 3), height: max(8, 40 * frac * 3))
                            Text(cat.shortTitle)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(RTColor.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .frame(height: 56)
            HStack {
                Text("Sleep·Vitals·Move share² · today")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("diffuse ← → narrow")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityHHI)
        .accessibilityLabel("Density HHI \(verb) \(hDisp)")
    }



    /// Honest #606: density max drawdown — peak→trough air-fill drop over window (Fitbit/GH graphics).
    @ViewBuilder
    private var densityDrawdownMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityDrawdownBody(days: days)
        }
    }

    private func densityDrawdownBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var peak = dens[0]
        var maxDD = 0.0
        var ddSeries: [Double] = []
        for d in dens {
            peak = max(peak, d)
            let dd = peak > 1e-9 ? (peak - d) / peak : 0
            maxDD = max(maxDD, dd)
            ddSeries.append(dd)
        }
        let verb: String
        let tone: Color
        if maxDD <= 0.12 {
            verb = "Shallow"; tone = RTColor.optimal
        } else if maxDD <= 0.28 {
            verb = "Moderate"; tone = RTColor.good
        } else {
            verb = "Deep"; tone = RTColor.warning
        }
        let ddPct = Int((maxDD * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density drawdown")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) −\(ddPct)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                Path { path in
                    for (i, dd) in ddSeries.enumerated() {
                        let x = w * Double(i) / Double(max(1, ddSeries.count - 1))
                        let y = h * (1.0 - dd)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                // max DD rule
                Path { path in
                    let y = h * (1.0 - maxDD)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(tone.opacity(0.55), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            .frame(height: 44)
            HStack {
                Text("peak→trough · last \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("shallow ← → deep")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityDrawdown)
        .accessibilityLabel("Density drawdown \(verb) \(ddPct) percent")
    }



    /// Honest #608: density rebound — recovery from max-drawdown trough toward prior peak (Fitbit/GH graphics).
    @ViewBuilder
    private var densityReboundMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityReboundBody(days: days)
        }
    }

    private func densityReboundBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        // Find peak→trough max drawdown trough index, then rebound to end.
        var peak = dens[0]
        var maxDD = 0.0
        var troughIdx = 0
        var troughVal = dens[0]
        for (i, d) in dens.enumerated() {
            if d >= peak {
                peak = d
            }
            let dd = peak > 1e-9 ? (peak - d) / peak : 0
            if dd >= maxDD {
                maxDD = dd
                troughIdx = i
                troughVal = d
            }
        }
        let peakAtTrough = dens[0...troughIdx].max() ?? peak
        let last = dens.last ?? troughVal
        let room = peakAtTrough - troughVal
        let rebound: Double
        if room <= 1e-9 || maxDD < 0.04 {
            rebound = maxDD < 0.04 ? 1.0 : 0.0
        } else {
            rebound = min(1.0, max(0.0, (last - troughVal) / room))
        }
        let verb: String
        let tone: Color
        if maxDD < 0.04 {
            verb = "Stable"; tone = RTColor.optimal
        } else if rebound >= 0.70 {
            verb = "Fast"; tone = RTColor.optimal
        } else if rebound >= 0.40 {
            verb = "Steady"; tone = RTColor.good
        } else {
            verb = "Slow"; tone = RTColor.warning
        }
        let reboundPct = Int((rebound * 100).rounded())
        let postSeries = Array(dens[troughIdx...])
        let seriesMax = max(postSeries.max() ?? 1, peakAtTrough, 1e-9)
        let seriesMin = min(postSeries.min() ?? 0, troughVal)
        let span = max(seriesMax - seriesMin, 1e-9)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.up")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density rebound")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(reboundPct)%")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            // Fill rail
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: w * rebound)
                }
            }
            .frame(height: 8)
            // Post-trough spark toward peak
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // peak rule
                Path { path in
                    let y = h * (1.0 - (peakAtTrough - seriesMin) / span)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(tone.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                Path { path in
                    for (i, d) in postSeries.enumerated() {
                        let x = w * Double(i) / Double(max(1, postSeries.count - 1))
                        let y = h * (1.0 - (d - seriesMin) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("trough→now · \(postSeries.count)d of \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("slow ← → fast")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityRebound)
        .accessibilityLabel("Density rebound \(verb) \(reboundPct) percent")
    }



    /// Honest #610: density Sharpe — mean/σ of air-fill over window (Fitbit/GH graphics).
    @ViewBuilder
    private var densitySharpeMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densitySharpeBody(days: days)
        }
    }

    private func densitySharpeBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let variance = dens.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / max(1, n - 1)
        let sigma = sqrt(variance)
        // Sharpe-like: excess vs 0.55 baseline fill / σ (unitless)
        let excess = mean - 0.55
        let sharpe = sigma > 1e-6 ? excess / sigma : (excess >= 0 ? 3.0 : -3.0)
        let clamped = max(-2.5, min(2.5, sharpe))
        let verb: String
        let tone: Color
        if sharpe >= 1.0 {
            verb = "Strong"; tone = RTColor.optimal
        } else if sharpe >= 0.25 {
            verb = "Solid"; tone = RTColor.good
        } else if sharpe >= -0.25 {
            verb = "Flat"; tone = RTColor.caution
        } else {
            verb = "Weak"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", sharpe)
        let meanPct = Int((mean * 100).rounded())
        let sigPct = Int((sigma * 100).rounded())
        // normalize spark around mean
        let lo = (dens.min() ?? 0)
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density Sharpe")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            // Zero-centered Sharpe bar (−2.5…+2.5)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let mid = w / 2
                let frac = CGFloat(abs(clamped) / 2.5)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, mid * frac))
                        .offset(x: clamped >= 0 ? mid : mid - mid * frac)
                    Rectangle()
                        .fill(RTColor.tertiaryText.opacity(0.4))
                        .frame(width: 1.5, height: 12)
                        .offset(x: mid)
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // mean rule
                Path { path in
                    let y = h * (1.0 - (mean - lo) / span)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(tone.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("μ \(meanPct)% · σ \(sigPct)% · vs 55% · \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("weak ← → strong")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySharpe)
        .accessibilityLabel("Density Sharpe \(verb) \(disp)")
    }



    /// Honest #612: density Sortino — excess vs 55% / downside σ (Fitbit/GH graphics).
    @ViewBuilder
    private var densitySortinoMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densitySortinoBody(days: days)
        }
    }

    private func densitySortinoBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let target = 0.55
        let downside = dens.map { min(0, $0 - target) }
        let downVar = downside.map { $0 * $0 }.reduce(0, +) / max(1, n - 1)
        let downSigma = sqrt(downVar)
        let excess = mean - target
        let sortino = downSigma > 1e-6 ? excess / downSigma : (excess >= 0 ? 3.0 : -3.0)
        let clamped = max(-2.5, min(2.5, sortino))
        let verb: String
        let tone: Color
        if sortino >= 1.2 {
            verb = "Protected"; tone = RTColor.optimal
        } else if sortino >= 0.35 {
            verb = "Cushioned"; tone = RTColor.good
        } else if sortino >= -0.2 {
            verb = "Exposed"; tone = RTColor.caution
        } else {
            verb = "Fragile"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", sortino)
        let meanPct = Int((mean * 100).rounded())
        let dSigPct = Int((downSigma * 100).rounded())
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density Sortino")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            // Zero-centered Sortino bar
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let mid = w / 2
                let frac = CGFloat(abs(clamped) / 2.5)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    // downside zone tint
                    Capsule()
                        .fill(RTColor.warning.opacity(0.12))
                        .frame(width: mid)
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, mid * frac))
                        .offset(x: clamped >= 0 ? mid : mid - mid * frac)
                    Rectangle()
                        .fill(RTColor.tertiaryText.opacity(0.4))
                        .frame(width: 1.5, height: 12)
                        .offset(x: mid)
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // target 55% rule
                Path { path in
                    let y = h * (1.0 - (target - lo) / span)
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: w, y: y))
                }
                .stroke(RTColor.warning.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                // downside fill under target
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (min(d, target) - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    let lastX = w
                    let targetY = h * (1.0 - (target - lo) / span)
                    path.addLine(to: CGPoint(x: lastX, y: targetY))
                    path.addLine(to: CGPoint(x: 0, y: targetY))
                    path.closeSubpath()
                }
                .fill(RTColor.warning.opacity(0.12))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("μ \(meanPct)% · ↓σ \(dSigPct)% · floor 55% · \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("fragile ← → protected")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensitySortino)
        .accessibilityLabel("Density Sortino \(verb) \(disp)")
    }



    /// Honest #614: density Calmar — (μ−55%) / max drawdown (Fitbit/GH graphics).
    @ViewBuilder
    private var densityCalmarMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityCalmarBody(days: days)
        }
    }

    private func densityCalmarBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let n = Double(dens.count)
        let mean = dens.reduce(0, +) / n
        let target = 0.55
        var peak = dens[0]
        var maxDD = 0.0
        var troughAt = 0
        var peakAt = 0
        var curPeakIdx = 0
        for (i, d) in dens.enumerated() {
            if d >= peak { peak = d; curPeakIdx = i }
            let dd = peak - d
            if dd > maxDD { maxDD = dd; troughAt = i; peakAt = curPeakIdx }
        }
        let excess = mean - target
        let calmar = maxDD > 1e-6 ? excess / maxDD : (excess >= 0 ? 3.0 : -3.0)
        let clamped = max(-2.0, min(2.0, calmar))
        let verb: String
        let tone: Color
        if calmar >= 1.0 {
            verb = "Resilient"; tone = RTColor.optimal
        } else if calmar >= 0.35 {
            verb = "Stable"; tone = RTColor.good
        } else if calmar >= 0 {
            verb = "Soft"; tone = RTColor.caution
        } else {
            verb = "Brittle"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", calmar)
        let meanPct = Int((mean * 100).rounded())
        let ddPct = Int((maxDD * 100).rounded())
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "mountain.2.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
                Text("Density Calmar")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let mid = w / 2
                let frac = CGFloat(abs(clamped) / 2.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [accent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, mid * frac))
                        .offset(x: clamped >= 0 ? mid : mid - mid * frac)
                    Rectangle()
                        .fill(RTColor.tertiaryText.opacity(0.4))
                        .frame(width: 1.5, height: 12)
                        .offset(x: mid)
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // drawdown band peak→trough
                if maxDD > 0, peakAt <= troughAt, dens.count > 1 {
                    let x0 = w * Double(peakAt) / Double(dens.count - 1)
                    let x1 = w * Double(troughAt) / Double(dens.count - 1)
                    let yPeak = h * (1.0 - (dens[peakAt] - lo) / span)
                    let yTrough = h * (1.0 - (dens[troughAt] - lo) / span)
                    Path { p in
                        p.move(to: CGPoint(x: x0, y: yPeak))
                        p.addLine(to: CGPoint(x: x1, y: yPeak))
                        p.addLine(to: CGPoint(x: x1, y: yTrough))
                        p.addLine(to: CGPoint(x: x0, y: yTrough))
                        p.closeSubpath()
                    }
                    .fill(RTColor.warning.opacity(0.14))
                }
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [accent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("μ \(meanPct)% · maxDD \(ddPct)pp · vs 55% · \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("brittle ← → resilient")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(SurfaceID.fitbitAirDensityCalmar)
        .accessibilityLabel("Density Calmar \(verb) \(disp)")
    }

    /// Honest #616: density Omega — gains above 55% / losses below (Fitbit/GH graphics).
    /// Honest #647: appleWatch / HealthKit uses Health pink + health.air.density.omega (#616 parity).
    @ViewBuilder
    private var densityOmegaMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityOmegaBody(days: days)
        }
    }

    private func densityOmegaBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let target = 0.55
        let gains = dens.map { max(0, $0 - target) }.reduce(0, +)
        let losses = dens.map { max(0, target - $0) }.reduce(0, +)
        let omega = losses > 1e-6 ? gains / losses : (gains > 0 ? 8.0 : 1.0)
        let clamped = max(0.0, min(4.0, omega))
        let verb: String
        let tone: Color
        if omega >= 2.0 {
            verb = "Abundant"; tone = RTColor.optimal
        } else if omega >= 1.0 {
            verb = "Favorable"; tone = RTColor.good
        } else if omega >= 0.5 {
            verb = "Even"; tone = RTColor.caution
        } else {
            verb = "Scarce"; tone = RTColor.warning
        }
        let disp = String(format: "%.2f", omega)
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Omega" : "Density Omega"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityOmega : SurfaceID.fitbitAirDensityOmega
        let gainPct = Int((gains / Double(max(1, dens.count)) * 100).rounded())
        let lossPct = Int((losses / Double(max(1, dens.count)) * 100).rounded())
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "scalemass.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            // Omega bar 0…4 (1.0 = parity marked)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat(clamped / 4.0)
                let parityX = w * 0.25 // omega=1
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                    Rectangle()
                        .fill(RTColor.tertiaryText.opacity(0.45))
                        .frame(width: 1.5, height: 12)
                        .offset(x: parityX)
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let yT = h * (1.0 - (target - lo) / span)
                // target rule
                Path { p in
                    p.move(to: CGPoint(x: 0, y: yT))
                    p.addLine(to: CGPoint(x: w, y: yT))
                }
                .stroke(RTColor.tertiaryText.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                // gain/loss fills vs target
                ForEach(Array(dens.enumerated()), id: \.offset) { i, d in
                    let x0 = w * Double(i) / Double(max(1, dens.count))
                    let bw = w / Double(max(1, dens.count)) * 0.7
                    let yD = h * (1.0 - (d - lo) / span)
                    let yTop = min(yD, yT)
                    let yBot = max(yD, yT)
                    Rectangle()
                        .fill(d >= target ? RTColor.optimal.opacity(0.28) : RTColor.warning.opacity(0.28))
                        .frame(width: bw, height: max(1, yBot - yTop))
                        .position(x: x0 + bw / 2, y: (yTop + yBot) / 2)
                }
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("gain/day \(gainPct)pp · loss/day \(lossPct)pp · thr 55% · \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("scarce ←1→ abundant")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
    }

    /// Honest #618: density Ulcer — RMS of peak drawdowns (Fitbit/GH graphics).
    /// Honest #646: appleWatch / HealthKit uses Health pink + health.air.density.ulcer (#618 parity).
    @ViewBuilder
    private var densityUlcerMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityUlcerBody(days: days)
        }
    }

    private func densityUlcerBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var peak = dens[0]
        var sq = 0.0
        var dds: [Double] = []
        for d in dens {
            if d >= peak { peak = d }
            let dd = max(0, peak - d)
            dds.append(dd)
            sq += dd * dd
        }
        let ulcer = sqrt(sq / Double(dens.count))
        let clamped = min(0.5, ulcer)
        let verb: String
        let tone: Color
        if ulcer <= 0.05 {
            verb = "Smooth"; tone = RTColor.optimal
        } else if ulcer <= 0.12 {
            verb = "Mild"; tone = RTColor.good
        } else if ulcer <= 0.22 {
            verb = "Rough"; tone = RTColor.caution
        } else {
            verb = "Ulcered"; tone = RTColor.warning
        }
        let disp = String(format: "%.1f", ulcer * 100)
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Ulcer" : "Density Ulcer"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityUlcer : SurfaceID.fitbitAirDensityUlcer
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)pp")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat(clamped / 0.5)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // drawdown shade under peak envelope
                Path { path in
                    var runPeak = dens[0]
                    for (i, d) in dens.enumerated() {
                        if d >= runPeak { runPeak = d }
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yP = h * (1.0 - (runPeak - lo) / span)
                        let yD = h * (1.0 - (d - lo) / span)
                        if i == 0 {
                            path.move(to: CGPoint(x: x, y: yP))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: yP))
                        }
                        _ = yD
                    }
                    for i in stride(from: dens.count - 1, through: 0, by: -1) {
                        let d = dens[i]
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yD = h * (1.0 - (d - lo) / span)
                        path.addLine(to: CGPoint(x: x, y: yD))
                    }
                    path.closeSubpath()
                }
                .fill(tone.opacity(0.16))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("RMS drawdown · \(dens.count)d peak envelope")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("smooth ← → ulcered")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp) pp")
    }

    /// Honest #620: density Sterling — mean lift / mean drawdown (Fitbit/GH graphics).
    /// Honest #645: appleWatch / HealthKit uses Health pink + health.air.density.sterling (#620 parity).
    @ViewBuilder
    private var densitySterlingMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densitySterlingBody(days: days)
        }
    }

    private func densitySterlingBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var peak = dens[0]
        var ddSum = 0.0
        var lifts: [Double] = []
        var dds: [Double] = []
        for i in dens.indices {
            let d = dens[i]
            if d >= peak { peak = d }
            let dd = max(0, peak - d)
            dds.append(dd)
            ddSum += dd
            if i > 0 {
                lifts.append(d - dens[i - 1])
            }
        }
        let meanDD = ddSum / Double(dens.count)
        let meanLift = lifts.isEmpty ? 0.0 : lifts.reduce(0, +) / Double(lifts.count)
        let sterling = meanDD < 1e-6 ? (meanLift > 0 ? 4.0 : 0.0) : meanLift / meanDD
        let clamped = max(-1.0, min(3.0, sterling))
        let verb: String
        let tone: Color
        if sterling >= 1.5 {
            verb = "Elite"; tone = RTColor.optimal
        } else if sterling >= 0.6 {
            verb = "Solid"; tone = RTColor.good
        } else if sterling >= 0.0 {
            verb = "Thin"; tone = RTColor.caution
        } else {
            verb = "Bleed"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", sterling)
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Sterling" : "Density Sterling"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensitySterling : SurfaceID.fitbitAirDensitySterling
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis.ascending")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                // map clamped [-1,3] → [0,1]
                let frac = CGFloat((clamped + 1.0) / 4.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // mean DD band under peak
                Path { path in
                    var runPeak = dens[0]
                    for (i, d) in dens.enumerated() {
                        if d >= runPeak { runPeak = d }
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yP = h * (1.0 - (runPeak - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: yP)) }
                        else { path.addLine(to: CGPoint(x: x, y: yP)) }
                    }
                    for i in stride(from: dens.count - 1, through: 0, by: -1) {
                        let d = dens[i]
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yD = h * (1.0 - (d - lo) / span)
                        path.addLine(to: CGPoint(x: x, y: yD))
                    }
                    path.closeSubpath()
                }
                .fill(tone.opacity(0.14))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("mean Δ / mean DD · \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("bleed ← → elite")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
    }

    /// Honest #622: density Burke — mean lift / √(mean sq DD) (Fitbit/GH graphics).
    /// Honest #644: appleWatch / HealthKit uses Health pink + health.air.density.burke (#622 parity).
    @ViewBuilder
    private var densityBurkeMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityBurkeBody(days: days)
        }
    }

    private func densityBurkeBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var peak = dens[0]
        var sq = 0.0
        var lifts: [Double] = []
        for i in dens.indices {
            let d = dens[i]
            if d >= peak { peak = d }
            let dd = max(0, peak - d)
            sq += dd * dd
            if i > 0 { lifts.append(d - dens[i - 1]) }
        }
        let rmsDD = sqrt(sq / Double(dens.count))
        let meanLift = lifts.isEmpty ? 0.0 : lifts.reduce(0, +) / Double(lifts.count)
        let burke = rmsDD < 1e-6 ? (meanLift > 0 ? 4.0 : 0.0) : meanLift / rmsDD
        let clamped = max(-1.0, min(3.0, burke))
        let verb: String
        let tone: Color
        if burke >= 1.8 {
            verb = "Prime"; tone = RTColor.optimal
        } else if burke >= 0.7 {
            verb = "Firm"; tone = RTColor.good
        } else if burke >= 0.0 {
            verb = "Soft"; tone = RTColor.caution
        } else {
            verb = "Sink"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", burke)
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Burke" : "Density Burke"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityBurke : SurfaceID.fitbitAirDensityBurke
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg.rectangle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat((clamped + 1.0) / 4.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                Path { path in
                    var runPeak = dens[0]
                    for (i, d) in dens.enumerated() {
                        if d >= runPeak { runPeak = d }
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yP = h * (1.0 - (runPeak - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: yP)) }
                        else { path.addLine(to: CGPoint(x: x, y: yP)) }
                    }
                    for i in stride(from: dens.count - 1, through: 0, by: -1) {
                        let d = dens[i]
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yD = h * (1.0 - (d - lo) / span)
                        path.addLine(to: CGPoint(x: x, y: yD))
                    }
                    path.closeSubpath()
                }
                .fill(tone.opacity(0.14))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("mean Δ / ulcer RMS · \(dens.count)d")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("sink ← → prime")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
    }


    /// Honest #624: density Martin — mean lift / mean DD (Fitbit graphics).
    /// Honest #642: appleWatch / HealthKit uses Health pink + health.air.density.martin (#624 parity).
    @ViewBuilder
    private var densityMartinMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityMartinBody(days: days)
        }
    }

    private func densityMartinBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var peak = dens[0]
        var ddSum = 0.0
        var lifts: [Double] = []
        for i in dens.indices {
            let d = dens[i]
            if d >= peak { peak = d }
            ddSum += max(0, peak - d)
            if i > 0 { lifts.append(d - dens[i - 1]) }
        }
        let meanDD = ddSum / Double(dens.count)
        let meanLift = lifts.isEmpty ? 0.0 : lifts.reduce(0, +) / Double(lifts.count)
        let martin = meanDD < 1e-6 ? (meanLift > 0 ? 4.0 : 0.0) : meanLift / meanDD
        let clamped = max(-1.0, min(3.0, martin))
        let verb: String
        let tone: Color
        if martin >= 1.5 {
            verb = "Cruising"; tone = RTColor.optimal
        } else if martin >= 0.6 {
            verb = "Steady"; tone = RTColor.good
        } else if martin >= 0.0 {
            verb = "Drag"; tone = RTColor.caution
        } else {
            verb = "Sink"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", martin)
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Martin" : "Density Martin"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityMartin : SurfaceID.fitbitAirDensityMartin
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis.circle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat((clamped + 1.0) / 4.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                // mean-DD band (peak − meanDD) dashed
                Path { path in
                    var runPeak = dens[0]
                    for (i, d) in dens.enumerated() {
                        if d >= runPeak { runPeak = d }
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yP = h * (1.0 - (runPeak - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: yP)) }
                        else { path.addLine(to: CGPoint(x: x, y: yP)) }
                    }
                    for i in stride(from: dens.count - 1, through: 0, by: -1) {
                        let d = dens[i]
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let yD = h * (1.0 - (d - lo) / span)
                        path.addLine(to: CGPoint(x: x, y: yD))
                    }
                    path.closeSubpath()
                }
                .fill(tone.opacity(0.14))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("mean Δ / mean DD · \(dens.count)d · \(source == .appleWatch ? "HealthKit" : "Fitbit/GH")")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("sink ← → cruising")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
    }


    /// Honest #627: density Kappa — mean excess vs 0.5 / LPM₂√ (Fitbit graphics).
    /// Honest #643: appleWatch / HealthKit uses Health pink + health.air.density.kappa (#627 parity).
    @ViewBuilder
    private var densityKappaMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityKappaBody(days: days)
        }
    }

    private func densityKappaBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        let tau = 0.5
        let mean = dens.reduce(0, +) / Double(dens.count)
        let lpm2 = dens.map { max(0, tau - $0) }.map { $0 * $0 }.reduce(0, +) / Double(dens.count)
        let downside = sqrt(lpm2)
        let kappa = downside < 1e-6 ? (mean >= tau ? 4.0 : 0.0) : (mean - tau) / downside
        let clamped = max(-1.0, min(3.0, kappa))
        let verb: String
        let tone: Color
        if kappa >= 1.5 {
            verb = "Strong"; tone = RTColor.optimal
        } else if kappa >= 0.5 {
            verb = "Firm"; tone = RTColor.good
        } else if kappa >= 0.0 {
            verb = "Soft"; tone = RTColor.caution
        } else {
            verb = "Thin"; tone = RTColor.warning
        }
        let disp = String(format: "%+.2f", kappa)
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Kappa" : "Density Kappa"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityKappa : SurfaceID.fitbitAirDensityKappa
        let lo = min(dens.min() ?? 0, tau)
        let hi = max(dens.max() ?? 1, tau, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat((clamped + 1.0) / 4.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let yTau = h * (1.0 - (tau - lo) / span)
                // downside fill under τ
                Path { path in
                    path.move(to: CGPoint(x: 0, y: yTau))
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (min(d, tau) - lo) / span)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: w, y: yTau))
                    path.closeSubpath()
                }
                .fill(tone.opacity(0.16))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: yTau))
                    path.addLine(to: CGPoint(x: w, y: yTau))
                }
                .stroke(RTColor.secondaryText.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            }
            .frame(height: 44)
            HStack {
                Text("excess vs 0.5 / √LPM₂ · \(dens.count)d · \(source == .appleWatch ? "HealthKit" : "Fitbit/GH")")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("thin ← → strong")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
    }


    /// Honest #628: density Gain/Pain — Σ up Δ / |Σ down Δ| (Fitbit graphics).
    /// Honest #640: appleWatch / HealthKit uses Health pink + health.air.density.gainpain.meter (#628 parity).
    @ViewBuilder
    private var densityGainPainMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 5 {
            EmptyView()
        } else {
            densityGainPainBody(days: days)
        }
    }

    private func densityGainPainBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var up = 0.0
        var down = 0.0
        var deltas: [Double] = []
        for i in 1..<dens.count {
            let d = dens[i] - dens[i - 1]
            deltas.append(d)
            if d >= 0 { up += d } else { down += -d }
        }
        let gp = down < 1e-6 ? (up > 0 ? 4.0 : 0.0) : up / down
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Gain/Pain" : "Density Gain/Pain"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityGainPainMeter : SurfaceID.fitbitAirDensityGainPain
        let clamped = max(0.0, min(4.0, gp))
        let verb: String
        let tone: Color
        if gp >= 2.0 {
            verb = "Bull"; tone = RTColor.optimal
        } else if gp >= 1.0 {
            verb = "Net+"; tone = RTColor.good
        } else if gp >= 0.5 {
            verb = "Mixed"; tone = RTColor.caution
        } else {
            verb = "Bleed"; tone = RTColor.warning
        }
        let disp = String(format: "%.2f", gp)
        let lo = dens.min() ?? 0
        let hi = max(dens.max() ?? 1, lo + 1e-9)
        let span = hi - lo
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.arrow.down.circle")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat(clamped / 4.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            // up vs down split bars
            HStack(spacing: 6) {
                let tot = max(up + down, 1e-9)
                GeometryReader { geo in
                    let w = max(geo.size.width, 1)
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(RTColor.optimal.opacity(0.85))
                            .frame(width: max(2, w * CGFloat(up / tot)))
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(RTColor.warning.opacity(0.85))
                            .frame(width: max(2, w * CGFloat(down / tot)))
                        Spacer(minLength: 0)
                    }
                }
                .frame(height: 10)
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                Path { path in
                    for (i, d) in dens.enumerated() {
                        let x = w * Double(i) / Double(max(1, dens.count - 1))
                        let y = h * (1.0 - (d - lo) / span)
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(
                    LinearGradient(colors: [meterAccent, tone], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
                ForEach(Array(deltas.enumerated()), id: \.offset) { i, dlt in
                    let x = w * Double(i + 1) / Double(max(1, dens.count - 1))
                    let y = h * (1.0 - (dens[i + 1] - lo) / span)
                    Circle()
                        .fill(dlt >= 0 ? RTColor.optimal : RTColor.warning)
                        .frame(width: 5, height: 5)
                        .position(x: x, y: y)
                }
            }
            .frame(height: 44)
            HStack {
                Text("Σ↑ / Σ↓ · \(dens.count)d · \(source == .appleWatch ? "HealthKit" : "Fitbit/GH")")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("bleed ← → bull")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
    }


    /// Honest #629: density Tail Ratio — mean top-tail Δ / |mean bottom-tail Δ| (Fitbit graphics).
    /// Honest #641: appleWatch / HealthKit uses Health pink + health.air.density.tail (#629 parity).
    @ViewBuilder
    private var densityTailMeter: some View {
        let days = Array(history.suffix(14))
        if days.count < 6 {
            EmptyView()
        } else {
            densityTailBody(days: days)
        }
    }

    private func densityTailBody(days: [DailyHealthData]) -> some View {
        let dens: [Double] = days.map { day in
            let chips = AirChip.all(from: day)
            guard !chips.isEmpty else { return 0 }
            return Double(chips.filter(\.filled).count) / Double(chips.count)
        }
        var deltas: [Double] = []
        for i in 1..<dens.count {
            deltas.append(dens[i] - dens[i - 1])
        }
        let sorted = deltas.sorted()
        let n = sorted.count
        // ~20% tails (at least 1 each) — honest for short 14d windows
        let k = max(1, n / 5)
        let bottom = Array(sorted.prefix(k))
        let top = Array(sorted.suffix(k))
        let meanBot = bottom.reduce(0, +) / Double(bottom.count)
        let meanTop = top.reduce(0, +) / Double(top.count)
        let absBot = abs(meanBot)
        let ratio = absBot < 1e-6 ? (meanTop > 0 ? 4.0 : 0.0) : meanTop / absBot
        let meterAccent = source == .appleWatch ? Color(hex: "FF2D55") : accent
        let title = source == .appleWatch ? "Health Density Tail" : "Density Tail"
        let sid = source == .appleWatch ? SurfaceID.healthAirDensityTail : SurfaceID.fitbitAirDensityTail
        let clamped = max(0.0, min(4.0, ratio))
        let verb: String
        let tone: Color
        if ratio >= 2.0 {
            verb = "Fat"; tone = RTColor.optimal
        } else if ratio >= 1.0 {
            verb = "Balanced"; tone = RTColor.good
        } else if ratio >= 0.5 {
            verb = "Lean"; tone = RTColor.caution
        } else {
            verb = "Left"; tone = RTColor.warning
        }
        let disp = String(format: "%.2f", ratio)
        let dLo = min(sorted.first ?? -0.01, -1e-6)
        let dHi = max(sorted.last ?? 0.01, 1e-6)
        let dSpan = dHi - dLo
        // simple 7-bin hist of deltas
        let bins = 7
        var counts = Array(repeating: 0, count: bins)
        for d in deltas {
            let t = (d - dLo) / max(dSpan, 1e-9)
            let idx = min(bins - 1, max(0, Int(t * Double(bins))))
            counts[idx] += 1
        }
        let maxC = max(counts.max() ?? 1, 1)
        let botCut = bottom.last ?? dLo
        let topCut = top.first ?? dHi
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(meterAccent)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("\(verb) \(disp)")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tone)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tone.opacity(0.12))
                    .clipShape(Capsule())
            }
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let frac = CGFloat(clamped / 4.0)
                ZStack(alignment: .leading) {
                    Capsule().fill(RTColor.tertiaryText.opacity(0.10))
                    Capsule()
                        .fill(LinearGradient(colors: [meterAccent.opacity(0.55), tone], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(3, w * frac))
                }
            }
            .frame(height: 12)
            // delta histogram with tail shading
            GeometryReader { geo in
                let w = max(geo.size.width, 1)
                let h = max(geo.size.height, 1)
                let bw = w / Double(bins)
                ForEach(0..<bins, id: \.self) { i in
                    let mid = dLo + (Double(i) + 0.5) * dSpan / Double(bins)
                    let isLeft = mid <= botCut
                    let isRight = mid >= topCut
                    let fill: Color = isLeft ? RTColor.warning.opacity(0.85)
                        : (isRight ? RTColor.optimal.opacity(0.85) : meterAccent.opacity(0.45))
                    let bh = h * Double(counts[i]) / Double(maxC)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(fill)
                        .frame(width: max(2, bw - 2), height: max(2, bh))
                        .position(x: bw * (Double(i) + 0.5), y: h - bh / 2)
                }
                // zero line
                let zx = w * (0 - dLo) / max(dSpan, 1e-9)
                Path { p in
                    p.move(to: CGPoint(x: zx, y: 0))
                    p.addLine(to: CGPoint(x: zx, y: h))
                }
                .stroke(RTColor.secondaryText.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
            .frame(height: 44)
            HStack {
                Text("μ↑tail / |μ↓tail| · \(k)/\(n) · \(dens.count)d · \(source == .appleWatch ? "HealthKit" : "Fitbit/GH")")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
                Spacer()
                Text("left ← → fat")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
            }
        }
        .padding(10)
        .background(meterAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(meterAccent.opacity(0.28), lineWidth: 1)
        )
        .accessibilityIdentifier(sid)
        .accessibilityLabel("\(title) \(verb) \(disp)")
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
                // Honest #552: filled/total progress (parity with Simulator tasks progress)
                let filledCount = chips.count - gapChips.count
                Text("\(filledCount)/\(chips.count)")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                    .accessibilityIdentifier(source == .appleWatch
                                            ? SurfaceID.healthAirGapsProgress
                                            : SurfaceID.fitbitAirGapsProgress)
                    .accessibilityLabel("Air gaps filled \(filledCount) of \(chips.count)")
                if !gapChips.isEmpty {
                    // Honest #550: cycle focus to next unfilled air field
                    Button {
                        Haptic.selectionChanged()
                        let ids = gapChips.map(\.id)
                        if let cur = focusedGapID, let idx = ids.firstIndex(of: cur) {
                            focusedGapID = ids[(idx + 1) % ids.count]
                        } else {
                            focusedGapID = ids.first
                        }
                    } label: {
                        Text("Fill next")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accent)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier(source == .appleWatch
                                            ? SurfaceID.healthAirGapsFill
                                            : SurfaceID.fitbitAirGapsFill)
                    .accessibilityLabel("Fill next air gap")
                }
                Text(source == .fitbit ? "Google Health" : "HealthKit")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accent)
            }
            // Honest #554: Sleep / Vitals / Move fill gauges (Google Health gap graphics)
            gapsCategoryGauges
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
        .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.healthAirDataGaps
                                 : SurfaceID.fitbitAirDataGaps)
        .accessibilityLabel(source == .appleWatch ? "Health air gaps" : "Air gaps")
    }


    /// Honest #554: interactive category fill gauges under air gaps (Google Health / Fitbit parity).
    /// Honest #637: HealthKit / appleWatch uses health.air.gaps.categories SID.
    private var gapsCategoryGauges: some View {
        HStack(spacing: 8) {
            ForEach(AirDensityCategory.allCases) { cat in
                let filled = cat.filledCount(in: chips)
                let total = cat.chipIDs.count
                let ratio = cat.fillRatio(in: chips)
                let gapsInCat = gapChips.filter { cat.chipIDs.contains($0.id) }
                Button {
                    Haptic.selectionChanged()
                    if focusedLegend == cat {
                        focusedLegend = nil
                    } else {
                        focusedLegend = cat
                        sparkMetric = cat.sparkMetric
                        sparkScrubIndex = nil
                        focusedGapID = gapsInCat.first?.id
                        selectedChipID = chips.first(where: { cat.chipIDs.contains($0.id) && $0.filled })?.id
                            ?? chips.first(where: { cat.chipIDs.contains($0.id) })?.id
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(cat.color)
                                .frame(width: 6, height: 6)
                            Text(cat.shortTitle)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(focusedLegend == cat ? Color.white : RTColor.primaryText)
                            Spacer(minLength: 0)
                            Text("\(filled)/\(total)")
                                .font(.caption2.weight(.bold).monospacedDigit())
                                .foregroundStyle(focusedLegend == cat ? Color.white.opacity(0.95) : cat.color)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(cat.color.opacity(focusedLegend == cat ? 0.35 : 0.18))
                                    .frame(height: 7)
                                Capsule()
                                    .fill(focusedLegend == cat ? Color.white : cat.color)
                                    .frame(width: max(7, geo.size.width * CGFloat(ratio)), height: 7)
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 10)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(focusedLegend == cat ? cat.color : cat.color.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(focusedLegend == cat ? cat.color.opacity(0.85) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(cat.title) air fill \(filled) of \(total)")
            }
        }
        .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.healthAirGapsCategories
                                 : SurfaceID.fitbitAirGapsCategories)
        .accessibilityLabel(source == .appleWatch
                            ? "Health air gaps category fill"
                            : "Air gaps category fill")
    }

    private var focusedGapHint: String {

        guard let id = focusedGapID, let gap = gapChips.first(where: { $0.id == id }) else {
            return source == .fitbit
                ? "Tap a gap · wear Fitbit overnight, open Fitbit app, then pull-to-refresh Google Health."
                : "Tap a gap · grant Health access or switch source to Fitbit for Google Health sync."
        }
        // Honest #637: HealthKit-aware copy when source == .appleWatch (Google Health–style guidance).
        if source == .appleWatch {
            switch gap.id {
            case "sleep":
                return "Sleep empty · wear Apple Watch overnight; Sleep in Health → Browse → Sleep."
            case "hrv":
                return "HRV empty · continuous Watch wear ≥4h overnight fills HRV (SDNN) in Health."
            case "rhr":
                return "RHR empty · resting heart needs quiet wake window; check Health → Heart."
            case "spo2":
                return "SpO₂ empty · enable Blood Oxygen in Watch settings; sync to Health."
            case "resp":
                return "Resp empty · respiratory rate lands with Watch sleep tracking in Health."
            case "skin":
                return "Skin empty · wrist temp needs Watch Ultra/Series overnight sleep focus."
            case "steps":
                return "Steps empty · walk with iPhone or Watch; pull-to-refresh Health Air."
            case "kcal", "amin", "basal":
                return "\(gap.label) empty · Move ring + basal energy sync from Watch/HealthKit."
            case "dist":
                return "Distance empty · outdoor walk/run with Watch GPS or iPhone co-presence."
            case "floors":
                return "Floors empty · climb stairs; Watch altimeter writes Flights Climbed to Health."
            default:
                return "\(gap.label) · grant Health access or wear Watch, then refresh."
            }
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

        let spark = chipMiniSpark(chip)

        VStack(alignment: .leading, spacing: 8) {
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
            spark
        }
    }

    /// Honest #531/#532: 7-day mini spark for the selected air chip; scrub syncs main spark.
    @ViewBuilder
    private func chipMiniSpark(_ chip: AirChip) -> some View {
        let points: [(date: Date, value: Double)] = history.suffix(7).compactMap { day in
            guard let metric = chip.metric else { return nil }
            let v = QuickTrendCard.metricValue(day, metric: metric) ?? 0
            return (date: day.date, value: v)
        }
        if points.contains(where: { $0.value > 0 }) {
            let scrub = sparkScrubIndex ?? (points.count - 1)
            let scrubClamped = min(max(0, scrub), max(0, points.count - 1))
            let scrubPt = points.indices.contains(scrubClamped) ? points[scrubClamped] : nil
            let positive = points.map(\.value).filter { $0 > 0 }
            let mean7 = positive.isEmpty ? 0.0 : positive.reduce(0, +) / Double(positive.count)
            let deltaVsMean: Double? = {
                guard let scrubPt, mean7 > 0 else { return nil }
                return scrubPt.value - mean7
            }()
            // Honest #537: peak day in the 7d window
            let peakIndex: Int? = {
                guard let maxV = points.map(\.value).max(), maxV > 0 else { return nil }
                return points.firstIndex(where: { $0.value == maxV })
            }()
            let peakPt: (date: Date, value: Double)? = peakIndex.flatMap { points.indices.contains($0) ? points[$0] : nil }
            // Honest #544: 7d min–max range (own row — avoids scrub-cluster crowding)
            let min7 = positive.min() ?? 0
            let max7 = positive.max() ?? 0
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(chip.label) · 7d")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(RTColor.tertiaryText)
                    Spacer(minLength: 0)
                    if let scrubPt {
                        Text(chipSparkValueText(chip, scrubPt.value))
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(accent)
                            .accessibilityIdentifier(SurfaceID.fitbitAirChipSparkScrub)
                            .accessibilityLabel("\(chip.label) scrub \(chipSparkValueText(chip, scrubPt.value))")
                    }
                    if let d = deltaVsMean {
                        let sign = d >= 0 ? "+" : ""
                        let tone: Color = abs(d / mean7) < 0.05 ? RTColor.secondaryText
                            : (d >= 0 ? RTColor.optimal : RTColor.warning)
                        Text("\(sign)\(chipSparkValueText(chip, abs(d)))")
                            .font(.caption2.weight(.bold).monospacedDigit())
                            .foregroundStyle(tone)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(tone.opacity(0.12))
                            .clipShape(Capsule())
                            .accessibilityIdentifier(SurfaceID.fitbitAirChipSparkDelta)
                            .accessibilityLabel("\(chip.label) delta versus seven day mean")
                    }
                    if mean7 > 0 {
                        Text("avg \(chipSparkValueText(chip, mean7))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(RTColor.tertiaryText)
                            .accessibilityIdentifier(SurfaceID.fitbitAirChipSparkMean)
                            .accessibilityLabel("\(chip.label) seven day mean")
                    }
                    if let peakPt {
                        Text("peak \(chipSparkValueText(chip, peakPt.value))")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accent.opacity(0.12))
                            .clipShape(Capsule())
                            .accessibilityIdentifier(SurfaceID.fitbitAirChipSparkPeak)
                            .accessibilityLabel("\(chip.label) seven day peak")
                    }
                }
                // Honest #544: dedicated min–max range strip (richer + always hittable)
                if max7 > 0 {
                    HStack(spacing: 8) {
                        Text("\(chipSparkValueText(chip, min7))–\(chipSparkValueText(chip, max7))")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(RTColor.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RTColor.secondaryText.opacity(0.10))
                            .clipShape(Capsule())
                            .accessibilityIdentifier(SurfaceID.fitbitAirChipSparkRange)
                            .accessibilityLabel("\(chip.label) seven day range")
                        GeometryReader { geo in
                            let span = max(max7 - min7, 0.0001)
                            let scrubFrac: CGFloat = {
                                guard let scrubPt else { return 0.5 }
                                return CGFloat((scrubPt.value - min7) / span)
                            }()
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(accent.opacity(0.18))
                                    .frame(height: 6)
                                Capsule()
                                    .fill(accent)
                                    .frame(width: max(6, geo.size.width * 0.08), height: 6)
                                    .offset(x: max(0, min(geo.size.width - 6, geo.size.width * scrubFrac - 3)))
                            }
                            .frame(maxHeight: .infinity, alignment: .center)
                        }
                        .frame(height: 14)
                        Text("range")
                            .font(.caption2)
                            .foregroundStyle(RTColor.tertiaryText)
                    }
                    .accessibilityElement(children: .contain)
                }
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { i, pt in
                        AreaMark(
                            x: .value("Day", pt.date),
                            y: .value(chip.label, pt.value)
                        )
                        .foregroundStyle(accent.opacity(0.2))
                        LineMark(
                            x: .value("Day", pt.date),
                            y: .value(chip.label, pt.value)
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        if scrubClamped == i {
                            PointMark(
                                x: .value("Day", pt.date),
                                y: .value(chip.label, pt.value)
                            )
                            .foregroundStyle(accent)
                            .symbolSize(48)
                        }
                        if peakIndex == i {
                            PointMark(
                                x: .value("Day", pt.date),
                                y: .value(chip.label, pt.value)
                            )
                            .foregroundStyle(accent.opacity(scrubClamped == i ? 0.0 : 1.0))
                            .symbolSize(scrubClamped == i ? 0 : 36)
                            .symbol(Circle())
                        }
                    }
                    // Honest #536: 7d mean reference (pairs with Δ capsule)
                    if mean7 > 0 {
                        RuleMark(y: .value("Avg", mean7))
                            .foregroundStyle(RTColor.secondaryText.opacity(0.55))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 36)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        chipSparkSelect(
                                            chip,
                                            at: value.location,
                                            proxy: proxy,
                                            geo: geo,
                                            count: points.count
                                        )
                                    }
                            )
                    }
                }
                .animation(.easeInOut(duration: 0.15), value: sparkScrubIndex)
            }
            .padding(8)
            .background(RTColor.surfaceHighlight, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityIdentifier(SurfaceID.fitbitAirChipMiniSpark)
            .accessibilityLabel("\(chip.label) seven day spark")
            .accessibilityHint("Drag to scrub and sync the main air spark")
        }
    }

    private func chipSparkValueText(_ chip: AirChip, _ value: Double) -> String {
        switch chip.id {
        case "sleep": return String(format: "%.1fh", value)
        case "hrv": return "\(Int(value)) ms"
        case "rhr": return "\(Int(value))"
        case "spo2": return String(format: "%.0f%%", value)
        case "steps": return "\(Int(value))"
        case "kcal", "basal": return "\(Int(value))"
        case "dist": return String(format: "%.1f km", value)
        case "floors": return "\(Int(value))"
        case "amin": return "\(Int(value))m"
        case "resp": return String(format: "%.1f", value)
        case "skin": return String(format: "%+.1f°", value)
        default: return String(format: "%.1f", value)
        }
    }

    private func chipSparkSelect(
        _ chip: AirChip,
        at location: CGPoint,
        proxy: ChartProxy,
        geo: GeometryProxy,
        count: Int
    ) {
        guard count > 0 else { return }
        let x = max(0, min(location.x, geo.size.width))
        let frac = geo.size.width > 0 ? x / geo.size.width : 0
        let best = min(count - 1, max(0, Int((frac * CGFloat(count)).rounded(.down))))
        let metricChanging = chip.airSparkMetric.map { $0 != sparkMetric } ?? false
        if let mapped = chip.airSparkMetric, metricChanging {
            sparkMetric = mapped
            // onChange(sparkMetric) clears scrub — restore after that runs.
            DispatchQueue.main.async {
                if sparkScrubIndex != best {
                    sparkScrubIndex = best
                    Haptic.selectionChanged()
                }
            }
        } else if sparkScrubIndex != best {
            sparkScrubIndex = best
            Haptic.selectionChanged()
        }
        _ = proxy
    }

    /// Honest #519: period mean for current spark metric.
    private var sparkPeriodMean: Double {
        let vals = sparkPoints.map(\.value).filter { $0 > 0 }
        guard !vals.isEmpty else { return 0 }
        return vals.reduce(0, +) / Double(vals.count)
    }

    private var sparkDeltaValue: Double? {
        let idx = sparkScrubIndex ?? (sparkPoints.isEmpty ? nil : sparkPoints.count - 1)
        guard let idx, sparkPoints.indices.contains(idx) else { return nil }
        let mean = sparkPeriodMean
        guard mean > 0 else { return nil }
        return sparkPoints[idx].value - mean
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
            // Honest #519: vs period mean delta (tap toggles abs / %)
            if let delta = sparkDeltaValue, sparkPeriodMean > 0 {
                Button {
                    Haptic.selectionChanged()
                    sparkDeltaAsPercent.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2.weight(.bold))
                        Text("vs \(sparkPeriod)d avg")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(sparkDeltaAsPercent
                             ? String(format: "%+.0f%%", delta / sparkPeriodMean * 100)
                             : sparkDeltaText(delta))
                            .font(.caption.weight(.bold).monospacedDigit())
                        Text(sparkDeltaAsPercent ? "pct" : "abs")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [
                                (delta >= 0 ? RTColor.optimal : RTColor.warning).opacity(0.95),
                                accent.opacity(0.85)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(SurfaceID.fitbitAirDataSparkDelta)
                .accessibilityLabel("Spark delta versus average")
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
                if sparkPeriodMean > 0 {
                    RuleMark(y: .value("Avg", sparkPeriodMean))
                        .foregroundStyle(RTColor.secondaryText.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
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

    private func sparkDeltaText(_ delta: Double) -> String {
        let sign = delta >= 0 ? "+" : ""
        switch sparkMetric {
        case .steps, .active: return "\(sign)\(Int(delta.rounded()))"
        case .sleep: return String(format: "%+.1fh", delta)
        case .hrv, .rhr: return "\(sign)\(Int(delta.rounded()))"
        case .spo2: return String(format: "%+.1f", delta)
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

    /// Honest #532: map chip → main air spark metric when one exists.
    var airSparkMetric: AirSparkMetric? {
        switch id {
        case "sleep": return .sleep
        case "hrv": return .hrv
        case "rhr": return .rhr
        case "spo2": return .spo2
        case "steps": return .steps
        case "kcal": return .active
        default: return nil
        }
    }

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


// MARK: - Honest #630: Fitbit / Google Health density detail sheet

/// Interactive density detail — scrub chart + richer Gain/Pain wells (Today tab).
struct FitbitAirDensityDetailSheet: View {
    let history: [DailyHealthData]
    let source: DataSource

    @Environment(\.dismiss) private var dismiss
    @State private var period: Int = 14
    @State private var scrubIndex: Int? = nil
    /// Honest #631: which category overlays are visible on the scrub chart.
    @State private var visibleCats: Set<AirDensityCategory> = Set(AirDensityCategory.allCases)

    /// Honest #635: HealthKit pink when Apple Watch source; Fitbit teal otherwise.
    private var accent: Color {
        source == .appleWatch ? Color(hex: "FF2D55") : Color(hex: "00B0B9")
    }

    private var days: [DailyHealthData] {
        Array(history.suffix(period))
    }

    private var densSeries: [(date: Date, density: Double)] {
        days.map { day in
            let chips = AirChip.all(from: day)
            let d: Double
            if chips.isEmpty { d = 0 }
            else { d = Double(chips.filter(\.filled).count) / Double(chips.count) }
            return (date: day.date, density: d)
        }
    }

    private var activeIndex: Int {
        scrubIndex ?? max(0, densSeries.count - 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    periodPicker
                    scrubHero
                    categoryOverlay
                    gainPainWells
                }
                .padding(16)
            }
            .background(RTColor.background.ignoresSafeArea())
            .navigationTitle(source == .fitbit ? "Fitbit Density" : "Health Density")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.healthAirDensityDetail
                                 : SurfaceID.fitbitAirDensityDetail)
        .accessibilityLabel(source == .appleWatch
                            ? "Health air density detail sheet"
                            : "Air density detail sheet")
    }

    private var periodPicker: some View {
        HStack(spacing: 8) {
            ForEach([7, 14, 30], id: \.self) { p in
                Button {
                    Haptic.selectionChanged()
                    period = p
                    scrubIndex = nil
                } label: {
                    Text("\(p)d")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(period == p ? Color.white : accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(period == p ? accent : accent.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            if densSeries.indices.contains(activeIndex) {
                let pt = densSeries[activeIndex]
                Text("\(Int((pt.density * 100).rounded()))%")
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.primaryText)
            }
        }
    }

    private var scrubHero: some View {
        let points = densSeries
        return VStack(alignment: .leading, spacing: 8) {
            Text("Density scrub")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.secondaryText)
            if points.count >= 2 {
                Chart {
                    ForEach(Array(points.enumerated()), id: \.offset) { i, pt in
                        AreaMark(
                            x: .value("Day", pt.date),
                            y: .value("Density", pt.density)
                        )
                        .foregroundStyle(accent.opacity(0.16))
                        LineMark(
                            x: .value("Day", pt.date),
                            y: .value("Density", pt.density)
                        )
                        .foregroundStyle(accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        if i == activeIndex {
                            RuleMark(x: .value("Scrub", pt.date))
                                .foregroundStyle(RTColor.secondaryText.opacity(0.45))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            PointMark(
                                x: .value("Day", pt.date),
                                y: .value("Density", pt.density)
                            )
                            .foregroundStyle(accent)
                            .symbolSize(72)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 180)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        selectScrub(at: value.location, proxy: proxy, geo: geo, count: points.count)
                                    }
                            )
                    }
                }
                .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.healthAirDensityDetailScrub
                                 : SurfaceID.fitbitAirDensityDetailScrub)
                .accessibilityLabel("Density scrub chart")
            } else {
                Text("Need more history to scrub")
                    .font(.caption)
                    .foregroundStyle(RTColor.tertiaryText)
            }
            // Honest #636: live scrub readout (date + density + fill + Δ)
            scrubReadout
        }
        .padding(12)
        .background(RTColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Honest #636: interactive scrub readout chip under the density chart.
    @ViewBuilder
    private var scrubReadout: some View {
        let pts = densSeries
        if pts.indices.contains(activeIndex) {
            let pt = pts[activeIndex]
            let day = days.indices.contains(activeIndex) ? days[activeIndex] : nil
            let chips = day.map { AirChip.all(from: $0) } ?? []
            let filled = chips.filter(\.filled).count
            let total = chips.count
            let pct = Int((pt.density * 100).rounded())
            let deltaPP: Int? = activeIndex > 0
                ? Int(((pt.density - pts[activeIndex - 1].density) * 100).rounded())
                : nil
            let dateStr = pt.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
            let deltaText: String = {
                guard let d = deltaPP else { return "—" }
                if d > 0 { return "Δ+\(d)pp" }
                if d < 0 { return "Δ\(d)pp" }
                return "Δ0pp"
            }()
            let deltaColor: Color = {
                guard let d = deltaPP else { return RTColor.tertiaryText }
                if d > 0 { return Color(hex: "34C759") }
                if d < 0 { return Color(hex: "FF3B30") }
                return RTColor.secondaryText
            }()
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(dateStr)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    Text("Scrub day")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                Spacer(minLength: 4)
                Text("\(pct)%")
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(accent)
                Text("\(filled)/\(max(total, 1))")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(RTColor.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(accent.opacity(0.12), in: Capsule())
                Text(deltaText)
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(deltaColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(deltaColor.opacity(0.12), in: Capsule())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RTColor.surfaceHighlight.opacity(0.65), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(accent.opacity(0.28), lineWidth: 1)
            )
            .accessibilityIdentifier(source == .appleWatch
                                     ? SurfaceID.healthAirDensityDetailScrubReadout
                                     : SurfaceID.fitbitAirDensityDetailScrubReadout)
            .accessibilityLabel("Scrub readout \(dateStr) \(pct) percent \(filled) of \(total) \(deltaText)")
        }
    }

    private func selectScrub(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy, count: Int) {
        guard count >= 1 else { return }
        let width = max(geo.size.width, 1)
        let frac = min(max(location.x / width, 0), 1)
        let best = count == 1 ? 0 : min(count - 1, max(0, Int((frac * CGFloat(count - 1)).rounded())))
        _ = proxy
        if scrubIndex != best {
            scrubIndex = best
            Haptic.selectionChanged()
        }
    }

    /// Honest #631: Sleep / Vitals / Move density overlays (Google Health multi-series).
    private var categoryOverlay: some View {
        let catSeries: [(cat: AirDensityCategory, points: [(date: Date, density: Double)])] = AirDensityCategory.allCases.map { cat in
            let pts = days.map { day -> (date: Date, density: Double) in
                let chips = AirChip.all(from: day)
                return (date: day.date, density: cat.fillRatio(in: chips))
            }
            return (cat: cat, points: pts)
        }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Category density")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                Spacer()
                Text("GH overlay")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accent)
            }
            HStack(spacing: 8) {
                ForEach(AirDensityCategory.allCases) { cat in
                    let on = visibleCats.contains(cat)
                    Button {
                        Haptic.selectionChanged()
                        if on {
                            if visibleCats.count > 1 { visibleCats.remove(cat) }
                        } else {
                            visibleCats.insert(cat)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(cat.color).frame(width: 8, height: 8)
                            Text(cat.title)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(on ? RTColor.primaryText : RTColor.tertiaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(on ? cat.color.opacity(0.14) : RTColor.surfaceHighlight.opacity(0.5))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(on ? cat.color.opacity(0.45) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(cat.title) overlay \(on ? "on" : "off")")
                }
            }
            if days.count >= 2 {
                Chart {
                    ForEach(catSeries, id: \.cat.id) { item in
                        if visibleCats.contains(item.cat) {
                            ForEach(Array(item.points.enumerated()), id: \.offset) { i, pt in
                                LineMark(
                                    x: .value("Day", pt.date),
                                    y: .value("Density", pt.density),
                                    series: .value("Cat", item.cat.title)
                                )
                                .foregroundStyle(item.cat.color)
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                                if i == activeIndex {
                                    PointMark(
                                        x: .value("Day", pt.date),
                                        y: .value("Density", pt.density)
                                    )
                                    .foregroundStyle(item.cat.color)
                                    .symbolSize(48)
                                }
                            }
                        }
                    }
                }
                .chartXAxis(.hidden)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { v in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 120)
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        selectScrub(at: value.location, proxy: proxy, geo: geo, count: densSeries.count)
                                    }
                            )
                    }
                }
                // Scrub callout for visible cats
                if densSeries.indices.contains(activeIndex) {
                    HStack(spacing: 8) {
                        ForEach(AirDensityCategory.allCases) { cat in
                            if visibleCats.contains(cat) {
                                let chips = AirChip.all(from: days[activeIndex])
                                let r = cat.fillRatio(in: chips)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cat.shortTitle)
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(cat.color)
                                    Text("\(Int((r * 100).rounded()))%")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(RTColor.primaryText)
                                }
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(cat.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
            } else {
                Text("Need more history for category overlays")
                    .font(.caption)
                    .foregroundStyle(RTColor.tertiaryText)
            }
        }
        .padding(12)
        .background(RTColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
        .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.healthAirDensityDetailCats
                                 : SurfaceID.fitbitAirDensityDetailCats)
        .accessibilityLabel("Category density overlays")
    }

    /// Richer Gain/Pain wells — day wells + cumulative Σ↑ / Σ↓ (builds on #628).
    private var gainPainWells: some View {
        let dens = densSeries.map(\.density)
        guard dens.count >= 5 else {
            return AnyView(EmptyView())
        }
        var up = 0.0
        var down = 0.0
        var deltas: [Double] = []
        for i in 1..<dens.count {
            let d = dens[i] - dens[i - 1]
            deltas.append(d)
            if d >= 0 { up += d } else { down += -d }
        }
        let gp = down < 1e-6 ? (up > 0 ? 4.0 : 0.0) : up / down
        let verb: String
        let tone: Color
        if gp >= 2.0 { verb = "Bull"; tone = RTColor.optimal }
        else if gp >= 1.0 { verb = "Net+"; tone = RTColor.good }
        else if gp >= 0.5 { verb = "Mixed"; tone = RTColor.caution }
        else { verb = "Bleed"; tone = RTColor.warning }
        let disp = String(format: "%.2f", gp)
        let maxAbs = max(deltas.map { abs($0) }.max() ?? 0.01, 0.01)

        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Gain / Pain wells")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(RTColor.secondaryText)
                    Spacer()
                    Text("\(verb) \(disp)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(tone)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(tone.opacity(0.12))
                        .clipShape(Capsule())
                }
                // Day wells
                GeometryReader { geo in
                    let w = max(geo.size.width, 1)
                    let h = max(geo.size.height, 1)
                    let n = max(deltas.count, 1)
                    let bw = w / Double(n)
                    let midY = h / 2
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: midY))
                        p.addLine(to: CGPoint(x: w, y: midY))
                    }
                    .stroke(RTColor.tertiaryText.opacity(0.35), lineWidth: 1)
                    ForEach(Array(deltas.enumerated()), id: \.offset) { i, dlt in
                        let bh = (abs(dlt) / maxAbs) * (h * 0.45)
                        let x = bw * (Double(i) + 0.5)
                        let y = dlt >= 0 ? midY - bh : midY
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(dlt >= 0 ? RTColor.optimal.opacity(0.85) : RTColor.warning.opacity(0.85))
                            .frame(width: max(3, bw * 0.7), height: max(2, bh))
                            .position(x: x, y: y + bh / 2)
                    }
                }
                .frame(height: 88)
                // Cumulative stacks
                HStack(spacing: 10) {
                    wellStat(title: "Σ Gain", value: String(format: "+%.2f", up), color: RTColor.optimal)
                    wellStat(title: "Σ Pain", value: String(format: "−%.2f", down), color: RTColor.warning)
                    wellStat(title: "Ratio", value: disp, color: tone)
                }
                Text("Day Δ wells · \(deltas.count) steps · \(period)d window")
                    .font(.caption2)
                    .foregroundStyle(RTColor.tertiaryText)
            }
            .padding(12)
            .background(RTColor.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(accent.opacity(0.22), lineWidth: 1)
            )
            .accessibilityIdentifier(source == .appleWatch
                                 ? SurfaceID.healthAirDensityDetailGainPain
                                 : SurfaceID.fitbitAirDensityDetailGainPain)
            .accessibilityLabel("Gain Pain wells \(verb) \(disp)")
        )
    }

    private func wellStat(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(RTColor.tertiaryText)
            Text(value)
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
