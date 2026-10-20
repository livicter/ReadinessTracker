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
                    .accessibilityIdentifier(SurfaceID.fitbitAirGapsProgress)
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
                    .accessibilityIdentifier(SurfaceID.fitbitAirGapsFill)
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
        .accessibilityIdentifier(SurfaceID.fitbitAirDataGaps)
        .accessibilityLabel("Air gaps")
    }


    /// Honest #554: interactive category fill gauges under air gaps (Google Health / Fitbit parity).
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
        .accessibilityIdentifier(SurfaceID.fitbitAirGapsCategories)
        .accessibilityLabel("Air gaps category fill")
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
