import SwiftUI

/// WHOOP / Apple Fitness–style HR zone breakdown for Recovery & Strain.
struct HeartRateZonesCard: View {
    let data: DailyHealthData

    private var metrics: HRZoneMetrics? {
        guard !data.hrSamples.isEmpty else { return nil }
        let resting = data.restingHeartRate > 0 ? data.restingHeartRate : 54
        let settingsMax = UserSettings.load().estimatedMaxHeartRate
        let maxHR = data.maxHeartRate
            ?? (settingsMax > 0 ? Double(settingsMax) : nil)
            ?? 190
        return HRZoneAnalyzer.analyze(
            samples: data.hrSamples,
            restingHR: resting,
            maxHR: maxHR
        )
    }

    var body: some View {
        if let metrics {
            NativeCard {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Heart Rate Zones")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(RTColor.primaryText)
                            Text("\(Int(metrics.totalMinutes.rounded())) min · %HRR")
                                .font(.subheadline)
                                .foregroundStyle(RTColor.secondaryText)
                        }
                        Spacer()
                        if let dominant = metrics.dominantZone {
                            Text(dominant.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(color(for: dominant))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(color(for: dominant).opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(metrics.buckets) { bucket in
                                if bucket.minutes > 0 {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(color(for: bucket.zone))
                                        .frame(width: max(4, geo.size.width * CGFloat(bucket.fraction)))
                                }
                            }
                        }
                    }
                    .frame(height: 12)
                    .accessibilityHidden(true)

                    VStack(spacing: 10) {
                        ForEach(metrics.buckets) { bucket in
                            zoneRow(bucket)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(SurfaceID.strainHRZones)
                .accessibilityLabel("Heart rate zones")
            }
        }
    }

    private func zoneRow(_ bucket: HRZoneBucket) -> some View {
        HStack(spacing: 10) {
            // Honest #105: Apple circular tint wells on zone ordinals.
            Text("\(bucket.zone.rawValue + 1)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color(for: bucket.zone))
                .frame(width: 26, height: 26)
                .background(color(for: bucket.zone).opacity(0.14))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(bucket.zone.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RTColor.primaryText)

            Spacer(minLength: 8)

            Text("\(Int(bucket.minutes.rounded())) min")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(RTColor.primaryText)
                .monospacedDigit()

            Text("\(Int((bucket.fraction * 100).rounded()))%")
                .font(.caption.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
                .monospacedDigit()
                .frame(width: 36, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(surfaceID(for: bucket.zone))
        .accessibilityLabel("\(bucket.zone.title) \(Int(bucket.minutes.rounded())) minutes, \(Int((bucket.fraction * 100).rounded())) percent")
    }

    private func surfaceID(for zone: HRZone) -> String {
        switch zone {
        case .rest: return SurfaceID.strainHRZoneRest
        case .light: return SurfaceID.strainHRZoneLight
        case .moderate: return SurfaceID.strainHRZoneModerate
        case .hard: return SurfaceID.strainHRZoneHard
        case .peak: return SurfaceID.strainHRZonePeak
        }
    }

    private func color(for zone: HRZone) -> Color {
        switch zone {
        case .rest: return RTColor.secondaryText
        case .light: return RTColor.optimal
        case .moderate: return RTColor.good
        case .hard: return RTColor.caution
        case .peak: return RTColor.warning
        }
    }
}
