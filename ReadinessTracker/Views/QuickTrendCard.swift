import SwiftUI

struct QuickTrend {
    let window: Int
    let average: Double
    let percentChange: Double
    let hasPriorWindow: Bool
    let strength: TrendAnalysisEngine.TrendStrength
    let sparkline: [Double]
}

struct QuickTrendCard: View {
    let metric: MetricType
    let history: [DailyHealthData]
    let window: Int

    private var trend: QuickTrend {
        QuickTrendCard.computeTrend(metric: metric, history: history, window: window)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        // Honest #78: Apple circular tint well on QuickTrendCard header.
                        Image(systemName: metric.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(metric.color)
                            .frame(width: 26, height: 26)
                            .background(metric.color.opacity(0.14))
                            .clipShape(Circle())
                            .accessibilityHidden(true)

                        Text(metric.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(RTColor.secondaryText)
                    }

                    Spacer()

                    Text(trend.strength.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(trend.strength.trendColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(trend.strength.trendColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(formattedAverage(trend.average))
                        .font(AppleTheme.cardValue)
                        .foregroundStyle(RTColor.primaryText)

                    Text(metric.unit)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                HStack(spacing: 4) {
                    Image(systemName: percentChangeDirection.systemImage)
                        .font(.caption.weight(.semibold))

                    Text(percentChangeText)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(percentChangeColor)

                if trend.sparkline.count >= 2 {
                    AnimatedSparkline(data: trend.sparkline, color: metric.color)
                        .frame(height: 32)
                } else {
                    // Keep card height consistent when the window has too few samples
                    Text("Not enough data")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RTColor.tertiaryText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
            }
        }
    }

    private var percentChange: Double { trend.percentChange }

    private var percentChangeDirection: TrendDirection {
        percentChange > 0 ? .up : percentChange < 0 ? .down : .flat
    }

    private var percentChangeText: String {
        guard trend.hasPriorWindow else { return "--" }
        let sign = percentChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", percentChange))% vs prior window"
    }

    private var percentChangeColor: Color {
        if metric.higherIsBetter {
            return percentChange >= 0 ? RTColor.optimal : RTColor.warning
        } else {
            return percentChange >= 0 ? RTColor.warning : RTColor.optimal
        }
    }

    private func formattedAverage(_ value: Double) -> String {
        switch metric {
        case .sleep, .respiratoryRate, .skinTemperature, .walkingDistance, .wheelchairDistance, .bodyMass, .bodyFat, .leanBodyMass, .waistCircumference, .bloodGlucose, .vo2Max, .mindfulMinutes, .timeInDaylight, .heartRateRecovery, .afBurden, .falls, .uvExposure, .wheelchairPushes, .peripheralPerfusion, .swimDistance, .environmentalAudio, .headphoneAudio, .envSoundReduction, .protein, .dietaryEnergy, .hydration, .caffeine, .toothbrushing, .handwashing, .dietaryCarbs, .dietaryFat, .dietaryFiber, .dietarySugar, .dietarySodium, .dietaryPotassium, .dietaryCholesterol, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminB12, .dietaryIron, .dietaryCalcium, .dietaryMagnesium, .dietaryZinc, .dietaryFolate, .dietaryVitaminA, .dietaryVitaminE, .dietaryVitaminK, .dietaryVitaminB6, .dietaryThiamin, .dietaryRiboflavin, .dietaryNiacin, .dietaryPhosphorus, .dietarySelenium, .dietaryCopper, .dietaryManganese, .dietaryBiotin, .dietaryPantothenicAcid, .dietaryChloride, .dietaryChromium, .dietaryMolybdenum, .dietaryIodine, .dietarySatFat, .dietaryMufa, .dietaryPufa, .cyclingDistance, .cyclingSpeed, .cyclingCadence:
            return String(format: "%.1f", value)
        case .hrv, .restingHR, .activeCalories, .steps, .flightsClimbed, .exerciseTime, .standHours, .standTime, .moveTime, .basalEnergy, .bloodGlucose, .vo2Max, .walkingHeartRate, .mindfulMinutes, .timeInDaylight, .heartRateRecovery, .afBurden, .falls, .uvExposure, .wheelchairPushes, .peripheralPerfusion, .swimDistance, .environmentalAudio, .headphoneAudio, .envSoundReduction, .protein, .dietaryEnergy, .hydration, .caffeine, .toothbrushing, .handwashing, .dietaryCarbs, .dietaryFat, .dietaryFiber, .dietarySugar, .dietarySodium, .dietaryPotassium, .dietaryCholesterol, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminB12, .dietaryIron, .dietaryCalcium, .dietaryMagnesium, .dietaryZinc, .dietaryFolate, .dietaryVitaminA, .dietaryVitaminE, .dietaryVitaminK, .dietaryVitaminB6, .dietaryThiamin, .dietaryRiboflavin, .dietaryNiacin, .dietaryPhosphorus, .dietarySelenium, .dietaryCopper, .dietaryManganese, .dietaryBiotin, .dietaryPantothenicAcid, .dietaryChloride, .dietaryChromium, .dietaryMolybdenum, .dietaryIodine, .dietarySatFat, .dietaryMufa, .dietaryPufa, .cyclingDistance, .cyclingSpeed, .cyclingCadence:
            return "\(Int(value))"
        case .bloodOxygen:
            return String(format: "%.0f", value)
        }
    }

    static func computeTrend(metric: MetricType, history: [DailyHealthData], window: Int) -> QuickTrend {
        let values = history.compactMap { metricValue($0, metric: metric) }
        let current = Array(values.suffix(window))
        let previous = Array(values.dropLast(window).suffix(window))

        let currentAvg = current.reduce(0, +) / Double(max(1, current.count))
        let previousAvg = previous.reduce(0, +) / Double(max(1, previous.count))
        let hasPriorWindow = !previous.isEmpty
        let percentChange = previousAvg > 0 ? (currentAvg - previousAvg) / previousAvg * 100 : 0

        let (slope, rSquared, _) = TrendAnalysisEngine.linearRegression(values: current)
        let strength = TrendAnalysisEngine.classifyTrend(slope: slope, rSquared: rSquared, metric: metric)

        return QuickTrend(
            window: window,
            average: currentAvg,
            percentChange: percentChange,
            hasPriorWindow: hasPriorWindow,
            strength: strength,
            sparkline: current
        )
    }

    static func metricValue(_ data: DailyHealthData, metric: MetricType) -> Double? {
        switch metric {
        case .sleep: return data.sleepHours
        case .hrv: return data.hrv
        case .restingHR: return data.restingHeartRate
        case .activeCalories: return data.activeCalories
        case .bloodOxygen: return data.bloodOxygen
        case .steps: return Double(data.steps)
        case .respiratoryRate: return data.respiratoryRate
        case .skinTemperature: return data.skinTemperature
        case .flightsClimbed: return data.flightsClimbed
        case .walkingDistance: return data.distanceWalkingRunningKm
        case .exerciseTime: return data.appleExerciseTimeMinutes
        case .standHours: return data.appleStandHours
        case .standTime: return data.appleStandTimeMinutes
        case .moveTime: return data.appleMoveTimeMinutes
        case .basalEnergy: return data.basalEnergyKcal
        case .wheelchairDistance: return data.distanceWheelchairKm
        case .bodyFat: return data.bodyFatPercent
        case .bodyMass: return data.bodyMassKg
        case .leanBodyMass: return data.leanBodyMassKg
        case .waistCircumference: return data.waistCircumferenceCm
        case .bloodGlucose: return data.bloodGlucoseMgDl
        case .vo2Max: return data.vo2Max
        case .walkingHeartRate: return data.walkingHeartRateAverage
        case .mindfulMinutes: return data.mindfulMinutes
        case .timeInDaylight: return data.timeInDaylightMinutes
        case .heartRateRecovery: return data.heartRateRecoveryOneMinuteBpm
        case .afBurden: return data.atrialFibrillationBurdenPercent
        case .falls: return data.numberOfTimesFallen
        case .uvExposure: return data.uvExposureIndex
        case .wheelchairPushes: return data.pushCount
        case .peripheralPerfusion: return data.peripheralPerfusionIndexPercent
        case .swimDistance: return data.distanceSwimmingMeters
        case .environmentalAudio: return data.environmentalAudioExposureDBA
        case .headphoneAudio: return data.headphoneAudioExposureDBA
        case .envSoundReduction: return data.environmentalSoundReductionDBA
        case .protein: return data.nutrition.proteinGrams
        case .dietaryEnergy: return data.nutrition.energyKcal
        case .hydration: return data.nutrition.waterLiters
        case .caffeine: return data.nutrition.caffeineMg
        case .toothbrushing: return data.toothbrushingMinutes
        case .handwashing: return data.handwashingMinutes
        case .dietaryCarbs: return data.nutrition.carbohydrateGrams
        case .dietaryFat: return data.nutrition.fatGrams
        case .dietaryFiber: return data.nutrition.fiberGrams
        case .dietarySugar: return data.nutrition.sugarGrams
        case .dietarySodium: return data.nutrition.sodiumMg
        case .dietaryPotassium: return data.nutrition.potassiumMg
        case .dietaryCholesterol: return data.nutrition.cholesterolMg
        case .dietaryVitaminC: return data.nutrition.vitaminCMg
        case .dietaryVitaminD: return data.nutrition.vitaminDIU
        case .dietaryVitaminB12: return data.nutrition.vitaminB12Mcg
        case .dietaryIron: return data.nutrition.ironMg
        case .dietaryCalcium: return data.nutrition.calciumMg
        case .dietaryMagnesium: return data.nutrition.magnesiumMg
        case .dietaryZinc: return data.nutrition.zincMg
        case .dietaryFolate: return data.nutrition.folateMcg
        case .dietaryVitaminA: return data.nutrition.vitaminAMcg
        case .dietaryVitaminE: return data.nutrition.vitaminEMg
        case .dietaryVitaminK: return data.nutrition.vitaminKMcg
        case .dietaryVitaminB6: return data.nutrition.vitaminB6Mg
        case .dietaryThiamin: return data.nutrition.thiaminMg
        case .dietaryRiboflavin: return data.nutrition.riboflavinMg
        case .dietaryNiacin: return data.nutrition.niacinMg
        case .dietaryPhosphorus: return data.nutrition.phosphorusMg
        case .dietarySelenium: return data.nutrition.seleniumMcg
        case .dietaryCopper: return data.nutrition.copperMg
        case .dietaryManganese: return data.nutrition.manganeseMg
        case .dietaryBiotin: return data.nutrition.biotinMcg
        case .dietaryPantothenicAcid: return data.nutrition.pantothenicAcidMg
        case .dietaryChloride: return data.nutrition.chlorideMg
        case .dietaryChromium: return data.nutrition.chromiumMcg
        case .dietaryMolybdenum: return data.nutrition.molybdenumMcg
        case .dietaryIodine: return data.nutrition.iodineMcg
        case .dietarySatFat: return data.nutrition.saturatedFatGrams
        case .dietaryMufa: return data.nutrition.monounsaturatedFatGrams
        case .dietaryPufa: return data.nutrition.polyunsaturatedFatGrams
        case .cyclingDistance: return data.distanceCyclingKm
        case .cyclingSpeed: return data.cyclingSpeedMps
        case .cyclingCadence: return data.cyclingCadenceRpm
        }
    }
}

extension TrendAnalysisEngine.TrendStrength {
    var trendColor: Color {
        switch self {
        case .strongUp, .moderateUp:
            return RTColor.optimal
        case .flat:
            return RTColor.tertiaryText
        case .moderateDown, .strongDown:
            return RTColor.warning
        }
    }
}
