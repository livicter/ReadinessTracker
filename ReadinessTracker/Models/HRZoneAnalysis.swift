import Foundation

/// WHOOP / Apple Fitness–style heart-rate zones from % heart-rate reserve (Karvonen).
enum HRZone: Int, CaseIterable, Identifiable, Hashable {
    case rest = 0
    case light = 1
    case moderate = 2
    case hard = 3
    case peak = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .rest: return "Rest"
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .hard: return "Hard"
        case .peak: return "Peak"
        }
    }

    /// Inclusive lower bound of %HRR for this zone (Peak has no upper).
    var lowerFraction: Double {
        switch self {
        case .rest: return 0.0
        case .light: return 0.50
        case .moderate: return 0.60
        case .hard: return 0.70
        case .peak: return 0.85
        }
    }

    var upperFraction: Double {
        switch self {
        case .rest: return 0.50
        case .light: return 0.60
        case .moderate: return 0.70
        case .hard: return 0.85
        case .peak: return 1.01
        }
    }

    var accessibilityShort: String {
        switch self {
        case .rest: return "rest"
        case .light: return "light"
        case .moderate: return "moderate"
        case .hard: return "hard"
        case .peak: return "peak"
        }
    }
}

struct HRZoneBucket: Hashable, Identifiable {
    let zone: HRZone
    let minutes: Double
    let fraction: Double

    var id: Int { zone.id }
}

struct HRZoneMetrics: Hashable {
    let buckets: [HRZoneBucket]
    let totalMinutes: Double
    let restingHR: Double
    let maxHR: Double

    var dominantZone: HRZone? {
        buckets.max(by: { $0.minutes < $1.minutes })?.zone
    }
}

enum HRZoneAnalyzer {
    /// Minute-binned %HRR zone distribution. Needs ≥5 samples and a valid reserve.
    static func analyze(
        samples: [HRSample],
        restingHR: Double,
        maxHR: Double
    ) -> HRZoneMetrics? {
        guard samples.count >= 5, restingHR > 0 else { return nil }
        let reserve = maxHR - restingHR
        guard reserve > 20 else { return nil }

        let grouped = Dictionary(grouping: samples) { sample -> Date in
            Calendar.current.dateInterval(of: .minute, for: sample.timestamp)?.start
                ?? sample.timestamp
        }

        var minutesByZone: [HRZone: Double] = Dictionary(
            uniqueKeysWithValues: HRZone.allCases.map { ($0, 0.0) }
        )

        for (_, minuteSamples) in grouped {
            let avgBPM = minuteSamples.map(\.bpm).reduce(0, +) / Double(minuteSamples.count)
            let fraction = max(0, min(1.0, (avgBPM - restingHR) / reserve))
            let zone = zone(for: fraction)
            minutesByZone[zone, default: 0] += 1
        }

        let total = minutesByZone.values.reduce(0, +)
        guard total > 0 else { return nil }

        let buckets = HRZone.allCases.map { zone in
            let minutes = minutesByZone[zone, default: 0]
            return HRZoneBucket(
                zone: zone,
                minutes: minutes,
                fraction: minutes / total
            )
        }

        return HRZoneMetrics(
            buckets: buckets,
            totalMinutes: total,
            restingHR: restingHR,
            maxHR: maxHR
        )
    }

    static func zone(for hrrFraction: Double) -> HRZone {
        for zone in HRZone.allCases.reversed() {
            if hrrFraction >= zone.lowerFraction {
                return zone
            }
        }
        return .rest
    }

    /// Synthetic daytime + workout progression for fixtures / empty HealthKit demos.
    static func syntheticSamples(
        on day: Date,
        restingHR: Double = 54,
        maxHR: Double = 185,
        count: Int = 120
    ) -> [HRSample] {
        let cal = Calendar.current
        let start = cal.date(bySettingHour: 7, minute: 0, second: 0, of: day) ?? day
        let reserve = max(maxHR - restingHR, 1)
        var samples: [HRSample] = []
        samples.reserveCapacity(count)

        for i in 0..<count {
            let t = start.addingTimeInterval(Double(i) * 60)
            // Quiet morning → progressive workout → cool-down.
            let phase = Double(i) / Double(max(count - 1, 1))
            let targetFraction: Double
            switch phase {
            case ..<0.25: targetFraction = 0.15 + phase * 0.4
            case ..<0.55: targetFraction = 0.55 + (phase - 0.25) * 0.9
            case ..<0.80: targetFraction = 0.75 + sin((phase - 0.55) * 12) * 0.12
            default: targetFraction = max(0.1, 0.7 - (phase - 0.80) * 2.0)
            }
            let wobble = sin(Double(i) * 0.37) * 3.0
            let bpm = restingHR + reserve * min(1.0, max(0.0, targetFraction)) + wobble
            samples.append(HRSample(timestamp: t, bpm: bpm))
        }
        return samples
    }
}
