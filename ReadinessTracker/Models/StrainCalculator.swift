import Foundation

enum StrainCalculator {
    /// Raw TRIMP-like points from HR samples (not normalized).
    static func sampleStrain(from data: DailyHealthData) -> Double {
        strainFromHRSamples(data)
    }

    /// WHOOP-style cardiovascular strain score, 0-21.
    /// Uses TRIMP-like exponential points based on heart-rate reserve.
    static func calculate(from data: DailyHealthData, history: [DailyHealthData]) -> Double {
        let sampleStrain = strainFromHRSamples(data)
        if sampleStrain > 0 {
            let maxStrain = maxHistoricalStrain(from: history, fallback: 7200)
            return min(21.0, (sampleStrain / max(maxStrain, 1.0)) * 21.0)
        }
        return fallbackStrain(from: data)
    }

    static func trimp(from samples: [HRSample], restingHR: Double, maxHR: Double) -> Double {
        let reserve = maxHR - restingHR
        guard reserve > 0 else { return 0 }

        var totalPoints: Double = 0
        let grouped = Dictionary(grouping: samples) { sample in
            Calendar.current.dateInterval(of: .minute, for: sample.timestamp)?.start
        }

        for (_, samples) in grouped {
            let avgBPM = samples.map(\.bpm).reduce(0, +) / Double(samples.count)
            let zone = max(0, min(1, (avgBPM - restingHR) / reserve))
            let points = 0.5 * exp(1.92 * zone)
            totalPoints += points
        }

        return totalPoints
    }

    private static func strainFromHRSamples(_ data: DailyHealthData) -> Double {
        guard data.restingHeartRate > 0,
              !data.hrSamples.isEmpty else { return 0 }

        let settingsMaxHR = UserSettings.load().estimatedMaxHeartRate
        guard let maxHR = data.maxHeartRate ?? (settingsMaxHR > 0 ? Double(settingsMaxHR) : nil) else { return 0 }

        return trimp(from: data.hrSamples, restingHR: data.restingHeartRate, maxHR: maxHR)
    }

    static func trimp(for session: StrainSession, using data: DailyHealthData) -> Double {
        guard data.restingHeartRate > 0 else { return 0 }
        let settingsMaxHR = UserSettings.load().estimatedMaxHeartRate
        guard let maxHR = data.maxHeartRate ?? (settingsMaxHR > 0 ? Double(settingsMaxHR) : nil) else { return 0 }

        let workoutSamples = data.hrSamples.filter { $0.timestamp >= session.startDate && $0.timestamp <= session.endDate }
        return trimp(from: workoutSamples, restingHR: data.restingHeartRate, maxHR: maxHR)
    }

    static func enrichSessions(
        _ sessions: [StrainSession],
        hrSamples: [HRSample],
        restingHR: Double,
        maxHR: Double?,
        history: [DailyHealthData] = []
    ) -> [StrainSession] {
        guard restingHR > 0,
              let effectiveMaxHR = maxHR ?? (UserSettings.load().estimatedMaxHeartRate > 0 ? Double(UserSettings.load().estimatedMaxHeartRate) : nil),
              !sessions.isEmpty else {
            return sessions
        }

        let enriched = sessions.map { session in
            let workoutSamples = hrSamples.filter { $0.timestamp >= session.startDate && $0.timestamp <= session.endDate }
            let trimp = Self.trimp(from: workoutSamples, restingHR: restingHR, maxHR: effectiveMaxHR)
            return StrainSession(
                id: session.id,
                workoutType: session.workoutType,
                startDate: session.startDate,
                endDate: session.endDate,
                trimp: trimp,
                contribution: 0
            )
        }

        let totalTRIMP = enriched.map(\.trimp).reduce(0, +)
        let totalDuration = enriched.map(\.durationMinutes).reduce(0, +)

        let placeholderData = DailyHealthData(
            date: Date(), source: .appleWatch,
            restingHeartRate: restingHR,
            workoutMinutes: Int(totalDuration),
            maxHeartRate: maxHR,
            hrSamples: hrSamples,
            strainSessions: sessions
        )
        let dailyStrain = calculate(from: placeholderData, history: history)

        guard totalTRIMP > 0 else {
            guard totalDuration > 0 else { return enriched }
            return enriched.map { session in
                StrainSession(
                    id: session.id,
                    workoutType: session.workoutType,
                    startDate: session.startDate,
                    endDate: session.endDate,
                    trimp: session.trimp,
                    contribution: (session.durationMinutes / totalDuration) * dailyStrain
                )
            }
        }

        return enriched.map { session in
            StrainSession(
                id: session.id,
                workoutType: session.workoutType,
                startDate: session.startDate,
                endDate: session.endDate,
                trimp: session.trimp,
                contribution: (session.trimp / totalTRIMP) * dailyStrain
            )
        }
    }

    private static func maxHistoricalStrain(from history: [DailyHealthData], fallback: Double) -> Double {
        let values = history.map { max(fallbackStrain(from: $0), strainFromHRSamples($0)) }.filter { $0 > 0 }
        guard let maxValue = values.max(), maxValue > 0 else { return fallback }
        return max(maxValue, fallback)
    }

    /// Fallback when no HR samples available.
    private static func fallbackStrain(from data: DailyHealthData) -> Double {
        let calScore = min(15, data.activeCalories / 200)
        let workoutScore = min(6, Double(data.workoutMinutes) / 30)
        return calScore + workoutScore
    }
}
