import Foundation

/// Pure helpers for Apple Health–style chart scrubbing: map a touch to the
/// nearest sample and format the date + value callout.
enum ChartScrubSelection {
    /// Index of the date nearest to `target`. Nil when `dates` is empty.
    static func nearestIndex(in dates: [Date], to target: Date) -> Int? {
        guard !dates.isEmpty else { return nil }
        return dates.indices.min(by: {
            abs(dates[$0].timeIntervalSince(target)) < abs(dates[$1].timeIntervalSince(target))
        })
    }

    /// Interpolate a date across `[first, last]` from a clamped horizontal fraction 0…1.
    /// Used on iOS 16 where `ChartProxy.plotFrame` is unavailable.
    static func date(atFraction fraction: Double, from first: Date, to last: Date) -> Date {
        let clamped = min(max(fraction, 0), 1)
        return first.addingTimeInterval(clamped * last.timeIntervalSince(first))
    }

    /// Callout copy shown near the scrub: "Sep 7: 58 ms".
    static func calloutText(date: Date, value: String, unit: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: date)): \(value) \(unit)"
    }
}
