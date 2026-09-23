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
    static let activeCaloriesCard = "body.calories.card"
    static let activeCaloriesBaselineCallout = "body.calories.baseline"
    static let activeCaloriesSpark = "body.calories.spark"
    static let hydrationCard = "body.hydration.card"
    static let hydrationBaselineCallout = "body.hydration.baseline"
    static let hydrationSpark = "body.hydration.spark"
    static let caffeineCard = "body.caffeine.card"
    static let caffeineBaselineCallout = "body.caffeine.baseline"
    static let caffeineSpark = "body.caffeine.spark"
    static let proteinCard = "body.protein.card"
    static let proteinBaselineCallout = "body.protein.baseline"
    static let proteinSpark = "body.protein.spark"
    static let dietaryEnergyCard = "body.energy.card"
    static let dietaryEnergyBaselineCallout = "body.energy.baseline"
    static let dietaryEnergySpark = "body.energy.spark"
    static let dietaryCarbsCard = "body.carbs.card"
    static let dietaryCarbsBaselineCallout = "body.carbs.baseline"
    static let dietaryCarbsSpark = "body.carbs.spark"
    static let dietaryFatCard = "body.fat.card"
    static let dietaryFatBaselineCallout = "body.fat.baseline"
    static let dietaryFatSpark = "body.fat.spark"
    static let dietaryFiberCard = "body.fiber.card"
    static let dietaryFiberBaselineCallout = "body.fiber.baseline"
    static let dietaryFiberSpark = "body.fiber.spark"
    static let dietarySugarCard = "body.sugar.card"
    static let dietarySugarBaselineCallout = "body.sugar.baseline"
    static let dietarySugarSpark = "body.sugar.spark"
    static let dietarySodiumCard = "body.sodium.card"
    static let dietarySodiumBaselineCallout = "body.sodium.baseline"
    static let dietarySodiumSpark = "body.sodium.spark"
    static let dietaryPotassiumCard = "body.potassium.card"
    static let dietaryPotassiumBaselineCallout = "body.potassium.baseline"
    static let dietaryPotassiumSpark = "body.potassium.spark"
    static let dietaryCholesterolCard = "body.cholesterol.card"
    static let dietaryCholesterolBaselineCallout = "body.cholesterol.baseline"
    static let dietaryCholesterolSpark = "body.cholesterol.spark"
    static let dietarySatFatCard = "body.satfat.card"
    static let dietarySatFatBaselineCallout = "body.satfat.baseline"
    static let dietarySatFatSpark = "body.satfat.spark"
    static let dietaryVitaminCCard = "body.vitaminc.card"
    static let dietaryVitaminCBaselineCallout = "body.vitaminc.baseline"
    static let dietaryVitaminCSpark = "body.vitaminc.spark"
    static let dietaryVitaminDCard = "body.vitamind.card"
    static let dietaryVitaminDBaselineCallout = "body.vitamind.baseline"
    static let dietaryVitaminDSpark = "body.vitamind.spark"
    static let dietaryVitaminB12Card = "body.b12.card"
    static let dietaryVitaminB12BaselineCallout = "body.b12.baseline"
    static let dietaryVitaminB12Spark = "body.b12.spark"
    static let dietaryIronCard = "body.iron.card"
    static let dietaryIronBaselineCallout = "body.iron.baseline"
    static let dietaryIronSpark = "body.iron.spark"
    static let dietaryCalciumCard = "body.calcium.card"
    static let dietaryCalciumBaselineCallout = "body.calcium.baseline"
    static let dietaryCalciumSpark = "body.calcium.spark"
    static let dietaryMagnesiumCard = "body.magnesium.card"
    static let dietaryMagnesiumBaselineCallout = "body.magnesium.baseline"
    static let dietaryMagnesiumSpark = "body.magnesium.spark"
    static let dietaryZincCard = "body.zinc.card"
    static let dietaryZincBaselineCallout = "body.zinc.baseline"
    static let dietaryZincSpark = "body.zinc.spark"
    static let dietaryFolateCard = "body.folate.card"
    static let dietaryFolateBaselineCallout = "body.folate.baseline"
    static let dietaryFolateSpark = "body.folate.spark"
    static let dietaryVitaminACard = "body.vitamina.card"
    static let dietaryVitaminABaselineCallout = "body.vitamina.baseline"
    static let dietaryVitaminASpark = "body.vitamina.spark"
    static let dietaryVitaminECard = "body.vitamine.card"
    static let dietaryVitaminEBaselineCallout = "body.vitamine.baseline"
    static let dietaryVitaminESpark = "body.vitamine.spark"
    static let dietaryVitaminKCard = "body.vitamink.card"
    static let dietaryVitaminKBaselineCallout = "body.vitamink.baseline"
    static let dietaryVitaminKSpark = "body.vitamink.spark"
    static let dietaryVitaminB6Card = "body.b6.card"
    static let dietaryVitaminB6BaselineCallout = "body.b6.baseline"
    static let dietaryVitaminB6Spark = "body.b6.spark"
    static let dietaryThiaminCard = "body.thiamin.card"
    static let dietaryThiaminBaselineCallout = "body.thiamin.baseline"
    static let dietaryThiaminSpark = "body.thiamin.spark"
    static let dietaryRiboflavinCard = "body.riboflavin.card"
    static let dietaryRiboflavinBaselineCallout = "body.riboflavin.baseline"
    static let dietaryRiboflavinSpark = "body.riboflavin.spark"
    static let dietaryNiacinCard = "body.niacin.card"
    static let dietaryNiacinBaselineCallout = "body.niacin.baseline"
    static let dietaryNiacinSpark = "body.niacin.spark"
    static let dietaryPantothenicAcidCard = "body.pantothenic.card"
    static let dietaryPantothenicAcidBaselineCallout = "body.pantothenic.baseline"
    static let dietaryPantothenicAcidSpark = "body.pantothenic.spark"
    static let dietaryBiotinCard = "body.biotin.card"
    static let dietaryBiotinBaselineCallout = "body.biotin.baseline"
    static let dietaryBiotinSpark = "body.biotin.spark"
    static let dietaryCopperCard = "body.copper.card"
    static let dietaryCopperBaselineCallout = "body.copper.baseline"
    static let dietaryCopperSpark = "body.copper.spark"
    static let dietarySeleniumCard = "body.selenium.card"
    static let dietarySeleniumBaselineCallout = "body.selenium.baseline"
    static let dietarySeleniumSpark = "body.selenium.spark"
    static let dietaryManganeseCard = "body.manganese.card"
    static let dietaryManganeseBaselineCallout = "body.manganese.baseline"
    static let dietaryManganeseSpark = "body.manganese.spark"
    static let dietaryIodineCard = "body.iodine.card"
    static let dietaryIodineBaselineCallout = "body.iodine.baseline"
    static let dietaryIodineSpark = "body.iodine.spark"
    static let dietaryPhosphorusCard = "body.phosphorus.card"
    static let dietaryPhosphorusBaselineCallout = "body.phosphorus.baseline"
    static let dietaryPhosphorusSpark = "body.phosphorus.spark"
    static let dietaryChromiumCard = "body.chromium.card"
    static let dietaryChromiumBaselineCallout = "body.chromium.baseline"
    static let dietaryChromiumSpark = "body.chromium.spark"
    static let dietaryMolybdenumCard = "body.molybdenum.card"
    static let dietaryMolybdenumBaselineCallout = "body.molybdenum.baseline"
    static let dietaryMolybdenumSpark = "body.molybdenum.spark"
    static let dietaryChlorideCard = "body.chloride.card"
    static let dietaryChlorideBaselineCallout = "body.chloride.baseline"
    static let dietaryChlorideSpark = "body.chloride.spark"
    static let dietaryMufaCard = "body.mufa.card"
    static let dietaryMufaBaselineCallout = "body.mufa.baseline"
    static let dietaryMufaSpark = "body.mufa.spark"
    static let dietaryPufaCard = "body.pufa.card"
    static let dietaryPufaBaselineCallout = "body.pufa.baseline"
    static let dietaryPufaSpark = "body.pufa.spark"
    static let alcoholicBeveragesCard = "body.alcohol.card"
    static let alcoholicBeveragesBaselineCallout = "body.alcohol.baseline"
    static let alcoholicBeveragesSpark = "body.alcohol.spark"
    static let inhalerUsageCard = "body.inhaler.card"
    static let inhalerUsageBaselineCallout = "body.inhaler.baseline"
    static let inhalerUsageSpark = "body.inhaler.spark"
    static let peakExpiratoryFlowCard = "body.pef.card"
    static let peakExpiratoryFlowBaselineCallout = "body.pef.baseline"
    static let peakExpiratoryFlowSpark = "body.pef.spark"
    static let forcedVitalCapacityCard = "body.fvc.card"
    static let forcedVitalCapacityBaselineCallout = "body.fvc.baseline"
    static let forcedVitalCapacitySpark = "body.fvc.spark"
    static let forcedExpiratoryVolume1Card = "body.fev1.card"
    static let forcedExpiratoryVolume1BaselineCallout = "body.fev1.baseline"
    static let forcedExpiratoryVolume1Spark = "body.fev1.spark"
    static let insulinDeliveryCard = "body.insulin.card"
    static let insulinDeliveryBaselineCallout = "body.insulin.baseline"
    static let insulinDeliverySpark = "body.insulin.spark"
    static let bloodGlucoseCard = "body.glucose.card"
    static let bloodGlucoseBaselineCallout = "body.glucose.baseline"
    static let bloodGlucoseSpark = "body.glucose.spark"
    static let bloodPressureCard = "body.bp.card"
    static let bloodPressureBaselineCallout = "body.bp.baseline"
    static let bloodPressureSpark = "body.bp.spark"
    static let bodyMassCard = "body.mass.card"
    static let bodyMassBaselineCallout = "body.mass.baseline"
    static let bodyMassSpark = "body.mass.spark"
    static let leanBodyMassCard = "body.lean.card"
    static let leanBodyMassBaselineCallout = "body.lean.baseline"
    static let leanBodyMassSpark = "body.lean.spark"
    static let waistCircumferenceCard = "body.waist.card"
    static let waistCircumferenceBaselineCallout = "body.waist.baseline"
    static let waistCircumferenceSpark = "body.waist.spark"
    static let bodyFatCard = "body.fat.card"
    static let bodyFatBaselineCallout = "body.fat.baseline"
    static let bodyFatSpark = "body.fat.spark"
    static let basalEnergyCard = "body.basal.card"
    static let basalEnergyBaselineCallout = "body.basal.baseline"
    static let basalEnergySpark = "body.basal.spark"
    static let toothbrushingCard = "body.brush.card"
    static let toothbrushingBaselineCallout = "body.brush.baseline"
    static let toothbrushingSpark = "body.brush.spark"
    static let handwashingCard = "body.wash.card"
    static let handwashingBaselineCallout = "body.wash.baseline"
    static let handwashingSpark = "body.wash.spark"
    static let mindfulCard = "body.mindful.card"
    static let mindfulBaselineCallout = "body.mindful.baseline"
    static let mindfulSpark = "body.mindful.spark"
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
    static let peakHRCard = "vitals.peakhr.card"
    static let peakHRBaselineCallout = "vitals.peakhr.baseline"
    static let peakHRSpark = "vitals.peakhr.spark"
    static let vo2MaxCard = "vitals.vo2.card"
    static let vo2MaxBaselineCallout = "vitals.vo2.baseline"
    static let vo2MaxSpark = "vitals.vo2.spark"
    static let walkingHRCard = "vitals.walkinghr.card"
    static let walkingHRBaselineCallout = "vitals.walkinghr.baseline"
    static let walkingHRSpark = "vitals.walkinghr.spark"
    static let heartRateRecoveryCard = "vitals.hrr.card"
    static let heartRateRecoveryBaselineCallout = "vitals.hrr.baseline"
    static let heartRateRecoverySpark = "vitals.hrr.spark"
    static let afBurdenCard = "vitals.afBurden.card"
    static let afBurdenBaselineCallout = "vitals.afBurden.baseline"
    static let afBurdenSpark = "vitals.afBurden.spark"
    static let peripheralPerfusionCard = "vitals.ppi.card"
    static let peripheralPerfusionBaselineCallout = "vitals.ppi.baseline"
    static let peripheralPerfusionSpark = "vitals.ppi.spark"
    static let fallsCard = "body.falls.card"
    static let fallsBaselineCallout = "body.falls.baseline"
    static let fallsSpark = "body.falls.spark"
    static let wheelchairPushesCard = "body.pushes.card"
    static let wheelchairPushesBaselineCallout = "body.pushes.baseline"
    static let wheelchairPushesSpark = "body.pushes.spark"
    static let wheelchairDistanceCard = "body.wheelchairDistance.card"
    static let wheelchairDistanceBaselineCallout = "body.wheelchairDistance.baseline"
    static let wheelchairDistanceSpark = "body.wheelchairDistance.spark"
    static let environmentalAudioCard = "vitals.envaudio.card"
    static let environmentalAudioBaselineCallout = "vitals.envaudio.baseline"
    static let environmentalAudioSpark = "vitals.envaudio.spark"
    static let headphoneAudioCard = "vitals.headaudio.card"
    static let headphoneAudioBaselineCallout = "vitals.headaudio.baseline"
    static let headphoneAudioSpark = "vitals.headaudio.spark"
    static let envSoundReductionCard = "vitals.soundred.card"
    static let envSoundReductionBaselineCallout = "vitals.soundred.baseline"
    static let envSoundReductionSpark = "vitals.soundred.spark"
    static let timeInDaylightCard = "vitals.daylight.card"
    static let timeInDaylightBaselineCallout = "vitals.daylight.baseline"
    static let timeInDaylightSpark = "vitals.daylight.spark"
    static let uvExposureCard = "vitals.uv.card"
    static let uvExposureBaselineCallout = "vitals.uv.baseline"
    static let uvExposureSpark = "vitals.uv.spark"
    static let flightsClimbedCard = "body.flights.card"
    static let flightsClimbedBaselineCallout = "body.flights.baseline"
    static let flightsClimbedSpark = "body.flights.spark"
    static let distanceCard = "body.distance.card"
    static let distanceBaselineCallout = "body.distance.baseline"
    static let distanceSpark = "body.distance.spark"
    static let walkingDoubleSupportCard = "body.doubleSupport.card"
    static let walkingDoubleSupportBaselineCallout = "body.doubleSupport.baseline"
    static let walkingDoubleSupportSpark = "body.doubleSupport.spark"
    static let walkingAsymmetryCard = "body.asymmetry.card"
    static let walkingAsymmetryBaselineCallout = "body.asymmetry.baseline"
    static let walkingAsymmetrySpark = "body.asymmetry.spark"
    static let walkingSpeedCard = "body.walkingSpeed.card"
    static let walkingSpeedBaselineCallout = "body.walkingSpeed.baseline"
    static let walkingSpeedSpark = "body.walkingSpeed.spark"
    static let walkingStepLengthCard = "body.stepLength.card"
    static let walkingStepLengthBaselineCallout = "body.stepLength.baseline"
    static let walkingStepLengthSpark = "body.stepLength.spark"
    static let walkingSteadinessCard = "body.steadiness.card"
    static let walkingSteadinessBaselineCallout = "body.steadiness.baseline"
    static let walkingSteadinessSpark = "body.steadiness.spark"
    static let stairAscentSpeedCard = "body.stairAscent.card"
    static let stairAscentSpeedBaselineCallout = "body.stairAscent.baseline"
    static let stairAscentSpeedSpark = "body.stairAscent.spark"
    static let stairDescentSpeedCard = "body.stairDescent.card"
    static let stairDescentSpeedBaselineCallout = "body.stairDescent.baseline"
    static let stairDescentSpeedSpark = "body.stairDescent.spark"
    static let sixMinuteWalkCard = "body.sixMinuteWalk.card"
    static let sixMinuteWalkBaselineCallout = "body.sixMinuteWalk.baseline"
    static let sixMinuteWalkSpark = "body.sixMinuteWalk.spark"
    static let swimDistanceCard = "body.swimDistance.card"
    static let swimDistanceBaselineCallout = "body.swimDistance.baseline"
    static let swimDistanceSpark = "body.swimDistance.spark"
    static let swimStrokesCard = "body.swimStrokes.card"
    static let swimStrokesBaselineCallout = "body.swimStrokes.baseline"
    static let swimStrokesSpark = "body.swimStrokes.spark"
    static let rowingDistanceCard = "body.rowingDistance.card"
    static let rowingDistanceBaselineCallout = "body.rowingDistance.baseline"
    static let rowingDistanceSpark = "body.rowingDistance.spark"
    static let rowingSpeedCard = "body.rowingSpeed.card"
    static let rowingSpeedBaselineCallout = "body.rowingSpeed.baseline"
    static let rowingSpeedSpark = "body.rowingSpeed.spark"
    static let paddleSportsDistanceCard = "body.paddleSportsDistance.card"
    static let paddleSportsDistanceBaselineCallout = "body.paddleSportsDistance.baseline"
    static let paddleSportsDistanceSpark = "body.paddleSportsDistance.spark"
    static let paddleSportsSpeedCard = "body.paddleSportsSpeed.card"
    static let paddleSportsSpeedBaselineCallout = "body.paddleSportsSpeed.baseline"
    static let paddleSportsSpeedSpark = "body.paddleSportsSpeed.spark"
    static let skatingSportsDistanceCard = "body.skatingSportsDistance.card"
    static let skatingSportsDistanceBaselineCallout = "body.skatingSportsDistance.baseline"
    static let skatingSportsDistanceSpark = "body.skatingSportsDistance.spark"
    static let crossCountrySkiingDistanceCard = "body.crossCountrySkiingDistance.card"
    static let crossCountrySkiingDistanceBaselineCallout = "body.crossCountrySkiingDistance.baseline"
    static let crossCountrySkiingDistanceSpark = "body.crossCountrySkiingDistance.spark"
    static let crossCountrySkiingSpeedCard = "body.crossCountrySkiingSpeed.card"
    static let crossCountrySkiingSpeedBaselineCallout = "body.crossCountrySkiingSpeed.baseline"
    static let crossCountrySkiingSpeedSpark = "body.crossCountrySkiingSpeed.spark"
    static let downhillSnowSportsDistanceCard = "body.downhillSnowSportsDistance.card"
    static let downhillSnowSportsDistanceBaselineCallout = "body.downhillSnowSportsDistance.baseline"
    static let downhillSnowSportsDistanceSpark = "body.downhillSnowSportsDistance.spark"
    static let cyclingCadenceCard = "body.cyclingCadence.card"
    static let cyclingCadenceBaselineCallout = "body.cyclingCadence.baseline"
    static let cyclingCadenceSpark = "body.cyclingCadence.spark"
    static let underwaterDepthCard = "body.underwaterDepth.card"
    static let underwaterDepthBaselineCallout = "body.underwaterDepth.baseline"
    static let underwaterDepthSpark = "body.underwaterDepth.spark"
    static let cyclingPowerCard = "body.cyclingPower.card"
    static let cyclingPowerBaselineCallout = "body.cyclingPower.baseline"
    static let cyclingPowerSpark = "body.cyclingPower.spark"
    static let cyclingFTPCard = "body.cyclingFTP.card"
    static let cyclingFTPBaselineCallout = "body.cyclingFTP.baseline"
    static let cyclingFTPSpark = "body.cyclingFTP.spark"
    static let cyclingDistanceCard = "body.cyclingDistance.card"
    static let cyclingDistanceBaselineCallout = "body.cyclingDistance.baseline"
    static let cyclingDistanceSpark = "body.cyclingDistance.spark"
    static let cyclingSpeedCard = "body.cyclingSpeed.card"
    static let cyclingSpeedBaselineCallout = "body.cyclingSpeed.baseline"
    static let cyclingSpeedSpark = "body.cyclingSpeed.spark"
    static let physicalEffortCard = "body.physicalEffort.card"
    static let physicalEffortBaselineCallout = "body.physicalEffort.baseline"
    static let physicalEffortSpark = "body.physicalEffort.spark"
    static let workoutEffortCard = "body.workoutEffort.card"
    static let workoutEffortBaselineCallout = "body.workoutEffort.baseline"
    static let workoutEffortSpark = "body.workoutEffort.spark"
    static let estimatedWorkoutEffortCard = "body.estimatedWorkoutEffort.card"
    static let estimatedWorkoutEffortBaselineCallout = "body.estimatedWorkoutEffort.baseline"
    static let estimatedWorkoutEffortSpark = "body.estimatedWorkoutEffort.spark"
    static let runningPowerCard = "body.runningPower.card"
    static let runningPowerBaselineCallout = "body.runningPower.baseline"
    static let runningPowerSpark = "body.runningPower.spark"
    static let runningSpeedCard = "body.runningSpeed.card"
    static let runningSpeedBaselineCallout = "body.runningSpeed.baseline"
    static let runningSpeedSpark = "body.runningSpeed.spark"
    static let runningGCTCard = "body.runningGCT.card"
    static let runningGCTBaselineCallout = "body.runningGCT.baseline"
    static let runningGCTSpark = "body.runningGCT.spark"
    static let runningStrideCard = "body.runningStride.card"
    static let runningStrideBaselineCallout = "body.runningStride.baseline"
    static let runningStrideSpark = "body.runningStride.spark"
    static let runningVOCard = "body.runningVO.card"
    static let runningVOBaselineCallout = "body.runningVO.baseline"
    static let runningVOSpark = "body.runningVO.spark"
    static let appleExerciseTimeCard = "strain.exerciseTime.card"
    static let appleExerciseTimeBaselineCallout = "strain.exerciseTime.baseline"
    static let appleExerciseTimeSpark = "strain.exerciseTime.spark"
    static let appleStandHoursCard = "strain.standHours.card"
    static let appleStandHoursBaselineCallout = "strain.standHours.baseline"
    static let appleStandHoursSpark = "strain.standHours.spark"
    static let appleStandTimeCard = "strain.standTime.card"
    static let appleStandTimeBaselineCallout = "strain.standTime.baseline"
    static let appleStandTimeSpark = "strain.standTime.spark"
    static let appleMoveTimeCard = "strain.moveTime.card"
    static let appleMoveTimeBaselineCallout = "strain.moveTime.baseline"
    static let appleMoveTimeSpark = "strain.moveTime.spark"
    static let watchStrainCard = "watch.strain.card"
    static let watchStrainBaselineCallout = "watch.strain.baseline"
    static let watchStrainSpark = "watch.strain.spark"
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
