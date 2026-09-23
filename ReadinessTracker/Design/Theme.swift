import SwiftUI

// MARK: - Color Palette (Bright / Apple Health Light)
enum RTColor {
    // systemGroupedBackground / secondarySystemGroupedBackground
    static let background = Color(hex: "F2F2F7")
    static let surface = Color.white
    static let surfaceElevated = Color(hex: "FFFFFF")
    static let surfaceHighlight = Color(hex: "E5E5EA")
    static let surfaceBorder = Color.black.opacity(0.08)
    
    static let primaryText = Color(hex: "1C1C1E")
    static let secondaryText = Color(hex: "8E8E93")
    // systemGray — readable on white cards (WCAG AA for captions)
    static let tertiaryText = Color(hex: "AEAEB2")
    
    // Zone colors - Apple system colors (light)
    static let optimal = Color(hex: "34C759")
    static let good = Color(hex: "30D158")
    static let caution = Color(hex: "FF9500")
    static let warning = Color(hex: "FF3B30")
    
    // Metric accent colors
    static let sleep = Color(hex: "5856D6")
    static let hrv = Color(hex: "34C759")
    static let recovery = Color(hex: "FF9500")
    static let strain = Color(hex: "FF3B30")
    static let consistency = Color(hex: "AF52DE")
    static let respiratory = Color(hex: "64D2FF")
    static let skinTemp = Color(hex: "FF9F0A")
    
    static let divider = Color.black.opacity(0.08)
    
    // App background (Apple Health grouped light)
    static let appBackgroundTop = Color(hex: "F2F2F7")
    static let appBackgroundBottom = Color(hex: "F2F2F7")
}

// MARK: - Typography
// Legacy fixed-size display fonts for hero numerals. For new reusable components
// prefer semantic text styles (`.headline`, `.caption`, …) so Dynamic Type scales.
enum RTFont {
    static let hero = Font.system(size: 72, weight: .bold, design: .rounded)
    static let heroMonospaced = Font.system(size: 72, weight: .bold, design: .rounded).monospacedDigit()
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    static let captionSmall = Font.system(size: 11, weight: .medium)
    
    static let metricValue = Font.system(size: 24, weight: .bold, design: .rounded).monospacedDigit()
    static let metricLabel = Font.system(size: 13, weight: .medium)
}

// MARK: - Layout
// Canonical layout tokens live in `AppleTheme` (AppleNativeTheme.swift).
// These forward so existing call sites keep working.
enum RTLayout {
    static var cardCornerRadius: CGFloat { AppleTheme.cornerRadiusLarge }
    static var cardPadding: CGFloat { AppleTheme.cardPadding }
    static var cardSpacing: CGFloat { AppleTheme.cardSpacing }
    static var sectionSpacing: CGFloat { AppleTheme.sectionSpacing }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Contrast Helpers
extension Color {
    /// Black or white — whichever yields higher WCAG contrast against this color.
    /// Use for text drawn on top of dynamic accent fills (e.g. sleep-stage segments).
    var contrastingTextColor: Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return .white }
        func linear(_ c: CGFloat) -> CGFloat { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
        return luminance > 0.179 ? .black : .white
    }
}

// MARK: - Score Zone Helpers
enum SurfaceID {
    static let whoopSection = "whoopSection"
    static let sleepHRVCard = "sleepHRVCard"
    static let sleepDebtCard = "sleepDebtCard"
    static let sleepDebtHours = "sleep.debt.hours"
    static let sleepDebtPayback = "sleep.debt.payback"
    static let sleepDebtSpark = "sleep.debt.spark"
    static let sleepDebtBars = "sleep.debt.bars"
    static let sleepQualityTrend = "sleepQualityTrend"
    static let sleepConsistency = "sleepConsistency"
    static let sleepConsistencyScore = "sleep.consistency.score"
    static let sleepConsistencyDual = "sleep.consistency.dual"
    static let sleepConsistencyBedtime = "sleep.consistency.bedtime"
    static let sleepConsistencySpark = "sleep.consistency.spark"
    static let sleepQualityScore = "sleep.quality.score"
    static let sleepQualitySpark = "sleep.quality.spark"
    static let bodyActivitySection = "bodyActivitySection"
    static let settingsHealthKitConnect = "settings.healthkit.connect"
    static let settingsFitbitConnect = "settings.fitbit.connect"
    static let settingsDataSources = "settings.dataSources"
    static let metricChartScrub = "metric.chart.scrub"
    static let metricChartSelection = "metric.chart.selection"
    static let metricDetail = "metric.detail"
    static let strainRecoveryBalance = "strain.recovery.balance"
    static let strainRecoveryWheel = "strain.recovery.wheel"
    static let strainRecoveryWheelLegend = "strain.recovery.wheel.legend"
    static let strainRecoveryWheelRecovery = "strain.recovery.wheel.recovery"
    static let strainRecoveryWheelStrain = "strain.recovery.wheel.strain"
    static let strainHRZones = "strain.hr.zones"
    static let strainHRZoneRest = "strain.hr.zone.rest"
    static let strainHRZoneLight = "strain.hr.zone.light"
    static let strainHRZoneModerate = "strain.hr.zone.moderate"
    static let strainHRZoneHard = "strain.hr.zone.hard"
    static let strainHRZonePeak = "strain.hr.zone.peak"
    static let strainNutrition = "strain.nutrition"
    static let strainNutritionWater = "strain.nutrition.water"
    static let strainNutritionCaffeine = "strain.nutrition.caffeine"
    static let strainNutritionProtein = "strain.nutrition.protein"
    static let strainWorkouts = "strain.workouts"
    static let strainWorkoutSession = "strain.workout.session"
    static let strainWorkoutDuration = "strain.workout.duration"
    static let strainWorkoutTRIMP = "strain.workout.trimp"
    static let strainWorkoutHR = "strain.workout.hr"
    static let recoveryTrajectorySpark = "recovery.trajectory.spark"
    static let recommendationsSection = "recommendations.section"
    static let coachingFeed = "coaching.feed"
    static let sleepPerformance = "sleep.performance"
    static let sleepHRVBaselineCallout = "sleep.hrv.baseline"
    static let sleepHRVSpark = "sleep.hrv.spark"
    static let sleepHRVPoincare = "sleep.hrv.poincare"
    static let sleepHRVFrequency = "sleep.hrv.frequency"
    static let sleepHRVLF = "sleep.hrv.lf"
    static let sleepHRVHF = "sleep.hrv.hf"
    static let sleepHRVLFHF = "sleep.hrv.lfhf"
    static let respiratoryCard = "respiratory.card"
    static let respiratoryBaselineCallout = "respiratory.baseline"
    static let respiratorySpark = "respiratory.spark"
    static let skinTempCard = "skin.temp.card"
    static let skinTempBaselineCallout = "skin.temp.baseline"
    static let skinTempSpark = "skin.temp.spark"
    static let bloodOxygenCard = "blood.oxygen.card"
    static let bloodOxygenBaselineCallout = "blood.oxygen.baseline"
    static let bloodOxygenSpark = "blood.oxygen.spark"
    static let sleepLatencyCard = "sleep.latency.card"
    static let sleepLatencyBaselineCallout = "sleep.latency.baseline"
    static let sleepLatencySpark = "sleep.latency.spark"
    static let sleepEfficiencyCard = "sleep.efficiency.card"
    static let sleepEfficiencyBaselineCallout = "sleep.efficiency.baseline"
    static let sleepEfficiencySpark = "sleep.efficiency.spark"
    static let wakeEpisodesCard = "wake.episodes.card"
    static let wakeEpisodesBaselineCallout = "wake.episodes.baseline"
    static let wakeEpisodesSpark = "wake.episodes.spark"
    static let sleepMidpointCard = "sleep.midpoint.card"
    static let sleepMidpointBaselineCallout = "sleep.midpoint.baseline"
    static let sleepMidpointSpark = "sleep.midpoint.spark"
    static let timeInBedCard = "sleep.inbed.card"
    static let timeInBedBaselineCallout = "sleep.inbed.baseline"
    static let timeInBedSpark = "sleep.inbed.spark"
    static let awakeHoursCard = "sleep.awake.card"
    static let awakeHoursBaselineCallout = "sleep.awake.baseline"
    static let awakeHoursSpark = "sleep.awake.spark"
    static let coreSleepCard = "sleep.core.card"
    static let coreSleepBaselineCallout = "sleep.core.baseline"
    static let coreSleepSpark = "sleep.core.spark"
    static let workoutMinutesCard = "strain.workoutMinutes.card"
    static let workoutMinutesBaselineCallout = "strain.workoutMinutes.baseline"
    static let workoutMinutesSpark = "strain.workoutMinutes.spark"
    static let dailyTRIMPCard = "strain.trimp.card"
    static let dailyTRIMPBaselineCallout = "strain.trimp.baseline"
    static let dailyTRIMPSpark = "strain.trimp.spark"
    static let cycleCard = "body.cycle.card"
    static let cycleBaselineCallout = "body.cycle.baseline"
    static let cycleSpark = "body.cycle.spark"
    static let stepsCard = "body.steps.card"
    static let stepsBaselineCallout = "body.steps.baseline"
    static let stepsSpark = "body.steps.spark"
    static let hydrationCard = "body.hydration.card"
    static let hydrationBaselineCallout = "body.hydration.baseline"
    static let hydrationSpark = "body.hydration.spark"
    static let caffeineCard = "body.caffeine.card"
    static let caffeineBaselineCallout = "body.caffeine.baseline"
    static let caffeineSpark = "body.caffeine.spark"
    static let proteinCard = "body.protein.card"
    static let proteinBaselineCallout = "body.protein.baseline"
    static let proteinSpark = "body.protein.spark"
    static let checkInInsightsCard = "checkin.insights.card"
    static let checkInInsightsBaselineCallout = "checkin.insights.baseline"
    static let checkInInsightsSpark = "checkin.insights.spark"
    static let cognitiveLoadCard = "checkin.cognitive.card"
    static let cognitiveLoadBaselineCallout = "checkin.cognitive.baseline"
    static let cognitiveLoadSpark = "checkin.cognitive.spark"
    static let napCard = "checkin.nap.card"
    static let napBaselineCallout = "checkin.nap.baseline"
    static let napSpark = "checkin.nap.spark"
    static let workoutRPECard = "checkin.rpe.card"
    static let workoutRPEBaselineCallout = "checkin.rpe.baseline"
    static let workoutRPESpark = "checkin.rpe.spark"
    static let plannedIntensityCard = "checkin.plan.card"
    static let plannedIntensityBaselineCallout = "checkin.plan.baseline"
    static let plannedIntensitySpark = "checkin.plan.spark"
    static let journalImpactCard = "journal.impact.card"
    static let journalImpactBaselineCallout = "journal.impact.baseline"
    static let journalImpactSpark = "journal.impact.spark"
    static let sleepRestorativeCard = "sleep.restorative.card"
    static let sleepRestorativeDual = "sleep.restorative.dual"
    static let sleepRestorativeSpark = "sleep.restorative.spark"
    static let restingHRCard = "resting.hr.card"
    static let restingHRBaselineCallout = "resting.hr.baseline"
    static let restingHRSpark = "resting.hr.spark"
    static let trendsDetail = "trends.detail"
    static let trendsChartScrub = "trends.chart.scrub"
    static let trendsChartSelection = "trends.chart.selection"
    static let trendsSummary = "trends.summary"
    static let historyTrendsLink = "history.trends.link"
    static let dayDetail = "day.detail"
    static let dayDetailHeader = "day.detail.header"
    static let dayDetailStageChips = "day.detail.stageChips"
    static let dayDetailHypnogram = "day.detail.hypnogram"
    static let dayDetailCycles = "day.detail.cycles"
    static let bodyDetail = "body.detail"
    static let bodyTileSteps = "body.tile.steps"
    static let breathingSession = "breathing.session"
    static let breathingStart = "breathing.start"
    static let breathingPhase = "breathing.phase"
}

enum ScoreZone {
    case optimal, good, caution, warning
    
    init(score: Int) {
        switch score {
        case 80...100: self = .optimal
        case 60..<80: self = .good
        case 40..<60: self = .caution
        default: self = .warning
        }
    }
    
    var color: Color {
        switch self {
        case .optimal: return RTColor.optimal
        case .good: return RTColor.good
        case .caution: return RTColor.caution
        case .warning: return RTColor.warning
        }
    }
    
    var label: String {
        switch self {
        case .optimal: return "Good to go"
        case .good: return "Good to go"
        case .caution: return "Take it easy"
        case .warning: return "Rest needed"
        }
    }
    
    var glowColor: Color {
        color.opacity(0.3)
    }
}
