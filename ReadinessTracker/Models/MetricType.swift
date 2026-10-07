import SwiftUI

enum MetricType: String, CaseIterable {
    case sleep = "Sleep"
    case hrv = "HRV"
    case restingHR = "Resting HR"
    case activeCalories = "Active Calories"
    case bloodOxygen = "Blood Oxygen"
    case steps = "Steps"
    case respiratoryRate = "Respiratory Rate"
    case skinTemperature = "Skin Temperature"
    case flightsClimbed = "Flights Climbed"
    case walkingDistance = "Walking Distance"
    case exerciseTime = "Exercise Time"
    case standHours = "Stand Hours"
    case standTime = "Stand Time"
    case moveTime = "Move Time"
    case basalEnergy = "Basal Energy"
    case wheelchairDistance = "Wheelchair Distance"
    case bodyMass = "Body Mass"
    case bodyFat = "Body Fat"

    case leanBodyMass = "Lean Body Mass"

    case waistCircumference = "Waist Circumference"

    case bloodGlucose = "Blood Glucose"

    case vo2Max = "VO2 Max"

    case walkingHeartRate = "Walking Heart Rate"

    case mindfulMinutes = "Mindful"

    case timeInDaylight = "Time in Daylight"

    case heartRateRecovery = "HR Recovery"

    case afBurden = "AF Burden"

    case falls = "Falls"

    case uvExposure = "UV Exposure"

    case wheelchairPushes = "Wheelchair Pushes"

    case peripheralPerfusion = "Perfusion Index"

    case swimDistance = "Swim Distance"

    case environmentalAudio = "Environmental Audio"

    case headphoneAudio = "Headphone Audio"

    case envSoundReduction = "Sound Reduction"

    case protein = "Protein"

    case dietaryEnergy = "Dietary Energy"

    case hydration = "Hydration"

    case caffeine = "Caffeine"

    case toothbrushing = "Toothbrushing"

    case handwashing = "Handwashing"

    case dietaryCarbs = "Carbohydrates"

    case dietaryFat = "Dietary Fat"

    case dietaryFiber = "Dietary Fiber"

    case dietarySugar = "Dietary Sugar"

    case dietarySodium = "Dietary Sodium"

    case dietaryPotassium = "Dietary Potassium"

    case dietaryCholesterol = "Dietary Cholesterol"

    case dietaryVitaminC = "Vitamin C"

    case dietaryVitaminD = "Vitamin D"

    case dietaryVitaminB12 = "Vitamin B12"

    case dietaryIron = "Dietary Iron"

    case dietaryCalcium = "Dietary Calcium"

    case dietaryMagnesium = "Dietary Magnesium"

    case dietaryZinc = "Dietary Zinc"

    case dietaryFolate = "Dietary Folate"

    case dietaryVitaminA = "Vitamin A"

    case dietaryVitaminE = "Vitamin E"

    case dietaryVitaminK = "Vitamin K"

    case dietaryVitaminB6 = "Vitamin B6"

    case dietaryThiamin = "Dietary Thiamin"

    case dietaryRiboflavin = "Dietary Riboflavin"

    case dietaryNiacin = "Dietary Niacin"

    case dietaryPhosphorus = "Dietary Phosphorus"

    case dietarySelenium = "Dietary Selenium"

    case dietaryCopper = "Dietary Copper"

    case dietaryManganese = "Dietary Manganese"

    case dietaryBiotin = "Dietary Biotin"

    case dietaryPantothenicAcid = "Pantothenic Acid"

    case dietaryChloride = "Dietary Chloride"

    case dietaryChromium = "Dietary Chromium"

    case dietaryMolybdenum = "Dietary Molybdenum"

    case dietaryIodine = "Dietary Iodine"

    case dietarySatFat = "Saturated Fat"

    case dietaryMufa = "Monounsaturated Fat"

    case dietaryPufa = "Polyunsaturated Fat"

    case cyclingDistance = "Cycling Distance"

    case cyclingSpeed = "Cycling Speed"

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .hrv: return "waveform.path.ecg"
        case .restingHR: return "heart.fill"
        case .activeCalories: return "flame.fill"
        case .bloodOxygen: return "drop.fill"
        case .steps: return "figure.walk"
        case .respiratoryRate: return "lungs.fill"
        case .skinTemperature: return "thermometer.medium"
        case .flightsClimbed: return "figure.stairs"
        case .walkingDistance: return "figure.walk.motion"
        case .exerciseTime: return "figure.run"
        case .standHours: return "figure.stand"
        case .standTime: return "timer"
        case .moveTime: return "figure.walk"
        case .basalEnergy: return "flame"
        case .wheelchairDistance: return "figure.roll"
        case .bodyMass: return "scalemass"
        case .bodyFat: return "percent"
        case .leanBodyMass: return "figure.arms.open"
        case .waistCircumference: return "ruler"
        case .bloodGlucose: return "drop.fill"
        case .vo2Max: return "lungs.fill"
        case .walkingHeartRate: return "heart.fill"
        case .mindfulMinutes: return "brain.head.profile"
        case .timeInDaylight: return "sun.max.fill"
        case .heartRateRecovery: return "arrow.down.heart.fill"
        case .afBurden: return "waveform.path.ecg"
        case .falls: return "figure.fall"
        case .uvExposure: return "sun.max.trianglebadge.exclamationmark"
        case .wheelchairPushes: return "figure.roll"
        case .peripheralPerfusion: return "drop.triangle.fill"
        case .swimDistance: return "figure.pool.swim"
        case .environmentalAudio: return "speaker.wave.2.fill"
        case .headphoneAudio: return "headphones"
        case .envSoundReduction: return "ear.fill"
        case .protein: return "fork.knife"
        case .dietaryEnergy: return "flame.fill"
        case .hydration: return "drop.fill"
        case .caffeine: return "cup.and.saucer.fill"
        case .toothbrushing: return "mouth.fill"
        case .handwashing: return "hands.sparkles.fill"
        case .dietaryCarbs: return "chart.pie.fill"
        case .dietaryFat: return "drop.triangle.fill"
        case .dietaryFiber: return "leaf.fill"
        case .dietarySugar: return "cube.fill"
        case .dietarySodium: return "cube.fill"
        case .dietaryPotassium: return "leaf.fill"
        case .dietaryCholesterol: return "heart.fill"
        case .dietaryVitaminC: return "carrot.fill"
        case .dietaryVitaminD: return "sun.max.fill"
        case .dietaryVitaminB12: return "pills.fill"
        case .dietaryIron: return "fork.knife"
        case .dietaryCalcium: return "fork.knife"
        case .dietaryMagnesium: return "fork.knife"
        case .dietaryZinc: return "fork.knife"
        case .dietaryFolate: return "fork.knife"
        case .dietaryVitaminA: return "fork.knife"
        case .dietaryVitaminE: return "fork.knife"
        case .dietaryVitaminK: return "fork.knife"
        case .dietaryVitaminB6: return "fork.knife"
        case .dietaryThiamin: return "fork.knife"
        case .dietaryRiboflavin: return "fork.knife"
        case .dietaryNiacin: return "fork.knife"
        case .dietaryPhosphorus: return "fork.knife"
        case .dietarySelenium: return "fork.knife"
        case .dietaryCopper: return "fork.knife"
        case .dietaryManganese: return "fork.knife"
        case .dietaryBiotin: return "fork.knife"
        case .dietaryPantothenicAcid: return "fork.knife"
        case .dietaryChloride: return "fork.knife"
        case .dietaryChromium: return "fork.knife"
        case .dietaryMolybdenum: return "fork.knife"
        case .dietaryIodine: return "fork.knife"
        case .dietarySatFat: return "fork.knife"
        case .dietaryMufa: return "fork.knife"
        case .dietaryPufa: return "fork.knife"
        case .cyclingDistance: return "bicycle"
        case .cyclingSpeed: return "speedometer"
        }
    }

    var unit: String {
        switch self {
        case .sleep: return "h"
        case .hrv: return "ms"
        case .restingHR: return "bpm"
        case .activeCalories: return "cal"
        case .bloodOxygen: return "%"
        case .steps: return "steps"
        case .respiratoryRate: return "br/min"
        case .skinTemperature: return "°C"
        case .flightsClimbed: return "fl"
        case .walkingDistance: return "km"
        case .exerciseTime: return "min"
        case .standHours: return "h"
        case .standTime: return "min"
        case .moveTime: return "min"
        case .basalEnergy: return "cal"
        case .wheelchairDistance: return "km"
        case .bodyMass: return "kg"
        case .bodyFat: return "%"
        case .leanBodyMass: return "kg"
        case .waistCircumference: return "cm"
        case .bloodGlucose: return "mg/dL"
        case .vo2Max: return "ml/kg/min"
        case .walkingHeartRate: return "bpm"
        case .mindfulMinutes: return "min"
        case .timeInDaylight: return "min"
        case .heartRateRecovery: return "bpm"
        case .afBurden: return "%"
        case .falls: return "count"
        case .uvExposure: return "UVI"
        case .wheelchairPushes: return "pushes"
        case .peripheralPerfusion: return "%"
        case .swimDistance: return "m"
        case .environmentalAudio: return "dBA"
        case .headphoneAudio: return "dBA"
        case .envSoundReduction: return "dB"
        case .protein: return "g"
        case .dietaryEnergy: return "kcal"
        case .hydration: return "L"
        case .caffeine: return "mg"
        case .toothbrushing: return "min"
        case .handwashing: return "min"
        case .dietaryCarbs: return "g"
        case .dietaryFat: return "g"
        case .dietaryFiber: return "g"
        case .dietarySugar: return "g"
        case .dietarySodium: return "mg"
        case .dietaryPotassium: return "mg"
        case .dietaryCholesterol: return "mg"
        case .dietaryVitaminC: return "mg"
        case .dietaryVitaminD: return "IU"
        case .dietaryVitaminB12: return "mcg"
        case .dietaryIron: return "mg"
        case .dietaryCalcium: return "mg"
        case .dietaryMagnesium: return "mg"
        case .dietaryZinc: return "mg"
        case .dietaryFolate: return "mcg"
        case .dietaryVitaminA: return "mcg"
        case .dietaryVitaminE: return "mg"
        case .dietaryVitaminK: return "mcg"
        case .dietaryVitaminB6: return "mg"
        case .dietaryThiamin: return "mg"
        case .dietaryRiboflavin: return "mg"
        case .dietaryNiacin: return "mg"
        case .dietaryPhosphorus: return "mg"
        case .dietarySelenium: return "mcg"
        case .dietaryCopper: return "mg"
        case .dietaryManganese: return "mg"
        case .dietaryBiotin: return "mcg"
        case .dietaryPantothenicAcid: return "mg"
        case .dietaryChloride: return "mg"
        case .dietaryChromium: return "mcg"
        case .dietaryMolybdenum: return "mcg"
        case .dietaryIodine: return "mcg"
        case .dietarySatFat: return "g"
        case .dietaryMufa: return "g"
        case .dietaryPufa: return "g"
        case .cyclingDistance: return "km"
        case .cyclingSpeed: return "m/s"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return RTColor.sleep
        case .hrv: return RTColor.hrv
        case .restingHR: return RTColor.strain
        case .activeCalories: return RTColor.caution
        case .bloodOxygen: return RTColor.optimal
        case .steps: return RTColor.strain
        case .respiratoryRate: return RTColor.respiratory
        case .skinTemperature: return RTColor.skinTemp
        case .flightsClimbed: return Color(hex: "BF5AF2")
        case .walkingDistance: return Color(hex: "64D2FF")
        case .exerciseTime: return RTColor.strain
        case .standHours: return Color(hex: "64D2FF")
        case .standTime: return Color(hex: "64D2FF")
        case .moveTime: return Color(hex: "FF9F0A")
        case .basalEnergy: return Color(hex: "FF9500")
        case .wheelchairDistance: return Color(hex: "0A84FF")
        case .bodyMass: return Color(hex: "8E8E93")
        case .bodyFat: return Color(hex: "AF52DE")
        case .leanBodyMass: return Color(hex: "32ADE6")
        case .waistCircumference: return Color(hex: "FF9F0A")
        case .bloodGlucose: return Color(hex: "FF375F")
        case .vo2Max: return Color(hex: "30D158")
        case .walkingHeartRate: return Color(hex: "64D2FF")
        case .mindfulMinutes: return Color(hex: "BF5AF2")
        case .timeInDaylight: return Color(hex: "FFD60A")
        case .heartRateRecovery: return Color(hex: "FF375F")
        case .afBurden: return Color(hex: "BF5AF2")
        case .falls: return Color(hex: "FF9F0A")
        case .uvExposure: return Color(hex: "FF9F0A")
        case .wheelchairPushes: return Color(hex: "5AC8FA")
        case .peripheralPerfusion: return Color(hex: "32ADE6")
        case .swimDistance: return Color(hex: "64D2FF")
        case .environmentalAudio: return Color(hex: "BF5AF2")
        case .headphoneAudio: return Color(hex: "64D2FF")
        case .envSoundReduction: return Color(hex: "30D158")
        case .protein: return Color(hex: "34C759")
        case .dietaryEnergy: return Color(hex: "FF9500")
        case .hydration: return Color(hex: "5AC8FA")
        case .caffeine: return Color(hex: "AC8E68")
        case .toothbrushing: return Color(hex: "64D2FF")
        case .handwashing: return Color(hex: "5AC8FA")
        case .dietaryCarbs: return Color(hex: "AF52DE")
        case .dietaryFat: return Color(hex: "FFCC00")
        case .dietaryFiber: return Color(hex: "30D158")
        case .dietarySugar: return Color(hex: "FF2D55")
        case .dietarySodium: return Color(hex: "FF9500")
        case .dietaryPotassium: return Color(hex: "30D158")
        case .dietaryCholesterol: return Color(hex: "FF453A")
        case .dietaryVitaminC: return Color(hex: "FFD60A")
        case .dietaryVitaminD: return Color(hex: "FF9F0A")
        case .dietaryVitaminB12: return Color(hex: "64D2FF")
        case .dietaryIron: return Color(hex: "FF9F0A")
        case .dietaryCalcium: return Color(hex: "5AC8FA")
        case .dietaryMagnesium: return Color(hex: "BF5AF2")
        case .dietaryZinc: return Color(hex: "FFD60A")
        case .dietaryFolate: return Color(hex: "30D158")
        case .dietaryVitaminA: return Color(hex: "FF9500")
        case .dietaryVitaminE: return Color(hex: "AC8E68")
        case .dietaryVitaminK: return Color(hex: "32D74B")
        case .dietaryVitaminB6: return Color(hex: "5E5CE6")
        case .dietaryThiamin: return Color(hex: "FF6B6B")
        case .dietaryRiboflavin: return Color(hex: "FFB340")
        case .dietaryNiacin: return Color(hex: "FF375F")
        case .dietaryPhosphorus: return Color(hex: "6B8E9F")
        case .dietarySelenium: return Color(hex: "8E8E93")
        case .dietaryCopper: return Color(hex: "E37322")
        case .dietaryManganese: return Color(hex: "A2845E")
        case .dietaryBiotin: return Color(hex: "BF5AF2")
        case .dietaryPantothenicAcid: return Color(hex: "64D2FF")
        case .dietaryChloride: return Color(hex: "64D2FF")
        case .dietaryChromium: return Color(hex: "8E8E93")
        case .dietaryMolybdenum: return Color(hex: "5856D6")
        case .dietaryIodine: return Color(hex: "5AC8FA")
        case .dietarySatFat: return Color(hex: "FF9F0A")
        case .dietaryMufa: return Color(hex: "30D158")
        case .dietaryPufa: return Color(hex: "0A84FF")
        case .cyclingDistance: return Color(hex: "FF9F0A")
        case .cyclingSpeed: return Color(hex: "FF375F")
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .sleep, .hrv, .activeCalories, .bloodOxygen, .steps, .flightsClimbed, .walkingDistance, .exerciseTime, .standHours, .standTime, .moveTime, .basalEnergy, .wheelchairDistance, .bodyMass, .leanBodyMass, .vo2Max, .mindfulMinutes, .timeInDaylight, .heartRateRecovery, .wheelchairPushes, .peripheralPerfusion, .swimDistance, .envSoundReduction, .protein, .dietaryEnergy, .hydration, .toothbrushing, .handwashing, .dietaryCarbs, .dietaryFat, .dietaryFiber, .dietaryPotassium, .dietaryVitaminC, .dietaryVitaminD, .dietaryVitaminB12, .dietaryIron, .dietaryCalcium, .dietaryMagnesium, .dietaryZinc, .dietaryFolate, .dietaryVitaminA, .dietaryVitaminE, .dietaryVitaminK, .dietaryVitaminB6, .dietaryThiamin, .dietaryRiboflavin, .dietaryNiacin, .dietaryPhosphorus, .dietarySelenium, .dietaryCopper, .dietaryManganese, .dietaryBiotin, .dietaryPantothenicAcid, .dietaryChloride, .dietaryChromium, .dietaryMolybdenum, .dietaryIodine, .dietaryMufa, .dietaryPufa, .cyclingDistance, .cyclingSpeed: return true
        case .restingHR, .respiratoryRate, .skinTemperature, .bodyFat, .waistCircumference, .bloodGlucose, .walkingHeartRate, .afBurden, .falls, .uvExposure, .environmentalAudio, .headphoneAudio, .caffeine, .dietarySugar, .dietarySodium, .dietaryCholesterol, .dietarySatFat: return false
        }
    }

    func zone(for value: Double) -> MetricZone? {
        switch self {
        case .sleep:
            if value < 6 { return MetricZone(label: "Insufficient", color: RTColor.warning, description: "Aim for 7-9 hours") }
            if value < 7 { return MetricZone(label: "Low", color: RTColor.caution, description: "Getting close to optimal") }
            if value <= 9 { return MetricZone(label: "Optimal", color: RTColor.optimal, description: "Great sleep duration") }
            return MetricZone(label: "Excessive", color: RTColor.caution, description: "May indicate fatigue")
        case .hrv:
            if value < 30 { return MetricZone(label: "Low", color: RTColor.warning, description: "High stress or poor recovery") }
            if value < 50 { return MetricZone(label: "Moderate", color: RTColor.caution, description: "Room for improvement") }
            return MetricZone(label: "Good", color: RTColor.optimal, description: "Strong autonomic balance")
        case .restingHR:
            if value < 50 { return MetricZone(label: "Athletic", color: RTColor.optimal, description: "Excellent cardiovascular fitness") }
            if value < 70 { return MetricZone(label: "Normal", color: RTColor.caution, description: "Healthy range") }
            return MetricZone(label: "Elevated", color: RTColor.warning, description: "May indicate fatigue or stress")
        case .activeCalories:
            if value < 300 { return MetricZone(label: "Sedentary", color: RTColor.warning, description: "Try to move more") }
            if value < 500 { return MetricZone(label: "Light", color: RTColor.caution, description: "Moderate activity") }
            return MetricZone(label: "Active", color: RTColor.optimal, description: "Great energy expenditure")
        case .bloodOxygen:
            let percent = value > 1.0 ? value : value * 100.0
            if percent < 90 { return MetricZone(label: "Low", color: RTColor.warning, description: "May indicate hypoxemia") }
            if percent < 95 { return MetricZone(label: "Moderate", color: RTColor.caution, description: "Below optimal range") }
            return MetricZone(label: "Optimal", color: RTColor.optimal, description: "Healthy oxygen saturation")
        case .steps:
            if value < 4000 { return MetricZone(label: "Sedentary", color: RTColor.warning, description: "Try to move more") }
            if value < 7500 { return MetricZone(label: "Light", color: RTColor.caution, description: "Building toward goal") }
            if value < 10000 { return MetricZone(label: "On track", color: RTColor.good, description: "Near the 10k goal") }
            return MetricZone(label: "Goal hit", color: RTColor.optimal, description: "Great daily volume")
        case .respiratoryRate:
            if value < 12 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below typical resting range") }
            if value <= 18 { return MetricZone(label: "Normal", color: RTColor.optimal, description: "Healthy resting breaths/min") }
            if value <= 20 { return MetricZone(label: "Slightly Elevated", color: RTColor.caution, description: "Upper end of resting range") }
            return MetricZone(label: "Elevated", color: RTColor.warning, description: "Above typical resting range")
        case .skinTemperature:
            // Wrist/skin absolute °C bands (device-dependent; detail view still shows vs personal baseline on card).
            if value < 32.0 { return MetricZone(label: "Cool", color: RTColor.caution, description: "Below typical skin range") }
            if value <= 35.5 { return MetricZone(label: "Typical", color: RTColor.optimal, description: "Within common skin range") }
            if value <= 36.5 { return MetricZone(label: "Warm", color: RTColor.caution, description: "Upper end of skin range") }
            return MetricZone(label: "Hot", color: RTColor.warning, description: "Above typical skin range")
        case .flightsClimbed:
            if value < 5 { return MetricZone(label: "Low", color: RTColor.warning, description: "Few floors today") }
            if value < 10 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some elevation work") }
            if value < 15 { return MetricZone(label: "On track", color: RTColor.good, description: "Solid floor volume") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Great elevation day")
        case .walkingDistance:
            if value < 3 { return MetricZone(label: "Low", color: RTColor.warning, description: "Short walking distance") }
            if value < 5 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some walk volume") }
            if value < 8 { return MetricZone(label: "On track", color: RTColor.good, description: "Solid walk/run distance") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Great distance day")
        case .exerciseTime:
            if value < 15 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below typical exercise minutes") }
            if value < 30 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some exercise volume") }
            if value < 45 { return MetricZone(label: "On track", color: RTColor.good, description: "Solid exercise minutes") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Great exercise day")
        case .standHours:
            if value < 6 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below typical stand hours") }
            if value < 9 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some stand hours") }
            if value < 12 { return MetricZone(label: "On track", color: RTColor.good, description: "Near the 12-hour goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Stand ring goal hit")
        case .standTime:
            if value < 30 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below typical stand minutes") }
            if value < 60 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some stand time") }
            if value < 90 { return MetricZone(label: "On track", color: RTColor.good, description: "Solid stand minutes") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Strong stand time day")
        case .moveTime:
            if value < 15 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below typical move minutes") }
            if value < 30 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some move time") }
            if value < 45 { return MetricZone(label: "On track", color: RTColor.good, description: "Solid move minutes") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Great move time day")
        case .basalEnergy:
            if value < 1200 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below typical resting burn") }
            if value < 1400 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some basal energy") }
            if value < 1600 { return MetricZone(label: "On track", color: RTColor.good, description: "Solid resting burn") }
            return MetricZone(label: "Solid", color: RTColor.optimal, description: "Healthy basal energy")
        case .wheelchairDistance:
            if value < 1 { return MetricZone(label: "Low", color: RTColor.warning, description: "Short wheelchair distance") }
            if value < 3 { return MetricZone(label: "Building", color: RTColor.caution, description: "Some mobility volume") }
            if value < 5 { return MetricZone(label: "Active", color: RTColor.good, description: "Solid wheelchair distance") }
            return MetricZone(label: "High", color: RTColor.optimal, description: "Great mobility day")
        case .bodyMass:
            if value < 50 { return MetricZone(label: "Light", color: RTColor.caution, description: "Below common adult band") }
            if value < 90 { return MetricZone(label: "Typical", color: RTColor.optimal, description: "Within common adult band") }
            if value < 110 { return MetricZone(label: "Higher", color: RTColor.caution, description: "Upper end of common band") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above common adult band")
        case .bodyFat:
            if value < 10 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below common body-fat band") }
            if value < 25 { return MetricZone(label: "Typical", color: RTColor.optimal, description: "Within common body-fat band") }
            if value < 35 { return MetricZone(label: "Higher", color: RTColor.caution, description: "Upper end of common band") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above common body-fat band")
        case .leanBodyMass:
            if value < 40 { return MetricZone(label: "Light", color: RTColor.caution, description: "Below common lean-mass band") }
            if value < 70 { return MetricZone(label: "Typical", color: RTColor.optimal, description: "Within common lean-mass band") }
            if value < 90 { return MetricZone(label: "Higher", color: RTColor.caution, description: "Upper end of common band") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above common lean-mass band")
        case .waistCircumference:
            if value < 70 { return MetricZone(label: "Narrow", color: RTColor.caution, description: "Below common waist band") }
            if value < 94 { return MetricZone(label: "Typical", color: RTColor.optimal, description: "Within common waist band") }
            if value < 102 { return MetricZone(label: "Higher", color: RTColor.caution, description: "Upper end of common band") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above common waist band")
        case .bloodGlucose:
            if value < 70 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below common glucose band") }
            if value < 100 { return MetricZone(label: "Optimal", color: RTColor.optimal, description: "Within common fasting band") }
            if value < 126 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "Upper end of common band") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above common glucose band")
        case .vo2Max:
            if value < 38 { return MetricZone(label: "Building", color: RTColor.warning, description: "Below common fitness band") }
            if value < 45 { return MetricZone(label: "Fair", color: RTColor.caution, description: "Within common fitness band") }
            if value < 50 { return MetricZone(label: "Strong", color: RTColor.good, description: "Upper end of common band") }
            return MetricZone(label: "Elite", color: RTColor.optimal, description: "Above common fitness band")
        case .walkingHeartRate:
            if value < 90 { return MetricZone(label: "Easy", color: RTColor.optimal, description: "Low walking effort") }
            if value < 110 { return MetricZone(label: "Steady", color: RTColor.good, description: "Typical walking effort") }
            if value < 130 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "Higher walking effort") }
            return MetricZone(label: "High", color: RTColor.warning, description: "High walking effort")
        case .mindfulMinutes:
            if value < 5 { return MetricZone(label: "Light", color: RTColor.caution, description: "Below soft mindful band") }
            if value < 10 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft goal") }
            if value < 20 { return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~10 min band") }
            return MetricZone(label: "Deep", color: RTColor.optimal, description: "Above soft mindful band")
        case .timeInDaylight:
            if value < 30 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below common daylight band") }
            if value < 60 { return MetricZone(label: "Modest", color: RTColor.caution, description: "Approaching common band") }
            if value < 120 { return MetricZone(label: "Good", color: RTColor.good, description: "Within common daylight band") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Above common daylight band")
        case .heartRateRecovery:
            if value < 12 { return MetricZone(label: "Slow", color: RTColor.warning, description: "Below common HRR band") }
            if value < 18 { return MetricZone(label: "Fair", color: RTColor.caution, description: "Approaching common HRR band") }
            if value < 25 { return MetricZone(label: "Solid", color: RTColor.good, description: "Within common HRR band") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Above common HRR band")
        case .afBurden:
            if value < 0.5 { return MetricZone(label: "Low", color: RTColor.optimal, description: "Minimal AF burden") }
            if value < 2 { return MetricZone(label: "Modest", color: RTColor.good, description: "Within common AF band") }
            if value < 5 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "Upper end of common band") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above common AF band")
        case .falls:
            if value < 1 { return MetricZone(label: "None", color: RTColor.optimal, description: "No falls logged") }
            if value < 2 { return MetricZone(label: "One", color: RTColor.caution, description: "Single fall event") }
            if value < 4 { return MetricZone(label: "Few", color: RTColor.warning, description: "Multiple fall events") }
            return MetricZone(label: "Many", color: RTColor.warning, description: "Elevated fall count")
        case .uvExposure:
            if value < 3 { return MetricZone(label: "Low", color: RTColor.optimal, description: "Below moderate UV band") }
            if value < 6 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Moderate UV exposure") }
            if value < 8 { return MetricZone(label: "High", color: RTColor.caution, description: "High UV exposure") }
            return MetricZone(label: "Very High", color: RTColor.warning, description: "Very high UV exposure")
        case .wheelchairPushes:
            if value <= 0 { return MetricZone(label: "None", color: RTColor.secondaryText, description: "No pushes logged") }
            if value < 500 { return MetricZone(label: "Light", color: RTColor.caution, description: "Light wheelchair mobility") }
            if value < 2000 { return MetricZone(label: "Steady", color: RTColor.good, description: "Steady wheelchair mobility") }
            return MetricZone(label: "Active", color: RTColor.optimal, description: "Active wheelchair mobility")
        case .peripheralPerfusion:
            if value < 0.5 { return MetricZone(label: "Low", color: RTColor.warning, description: "Low peripheral perfusion") }
            if value < 2.0 { return MetricZone(label: "Fair", color: RTColor.caution, description: "Fair peripheral perfusion") }
            if value < 5.0 { return MetricZone(label: "Solid", color: RTColor.good, description: "Solid peripheral perfusion") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Strong peripheral perfusion")
        case .swimDistance:
            if value < 400 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below common swim band") }
            if value < 800 { return MetricZone(label: "Light", color: RTColor.caution, description: "Light swim volume") }
            if value < 1500 { return MetricZone(label: "Solid", color: RTColor.good, description: "Solid swim volume") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Strong swim volume")
        case .environmentalAudio:
            if value < 55 { return MetricZone(label: "Quiet", color: RTColor.optimal, description: "Quiet environmental band") }
            if value < 70 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Moderate environmental exposure") }
            if value < 80 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "Elevated environmental exposure") }
            return MetricZone(label: "Loud", color: RTColor.warning, description: "Loud environmental exposure")
        case .headphoneAudio:
            if value < 55 { return MetricZone(label: "Quiet", color: RTColor.optimal, description: "Quiet headphone band") }
            if value < 70 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Moderate headphone exposure") }
            if value < 80 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "Elevated headphone exposure") }
            return MetricZone(label: "Loud", color: RTColor.warning, description: "Loud headphone exposure")
        case .envSoundReduction:
            if value < 6 { return MetricZone(label: "Minimal", color: RTColor.warning, description: "Minimal ambient attenuation") }
            if value < 12 { return MetricZone(label: "Light", color: RTColor.caution, description: "Light ambient attenuation") }
            if value < 20 { return MetricZone(label: "Good", color: RTColor.good, description: "Good ambient attenuation") }
            return MetricZone(label: "Strong", color: RTColor.optimal, description: "Strong ambient attenuation")
        case .protein:
            if value < 50 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below soft ~100 g protein band") }
            if value < 75 { return MetricZone(label: "Building", color: RTColor.caution, description: "Approaching soft protein goal") }
            if value < 100 { return MetricZone(label: "On track", color: RTColor.good, description: "Near soft ~100 g protein goal") }
            return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Met soft ~100 g protein goal")
        case .dietaryEnergy:
            if value < 1000 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below soft ~2000 kcal band") }
            if value < 1500 { return MetricZone(label: "Building", color: RTColor.caution, description: "Approaching soft energy goal") }
            if value < 2000 { return MetricZone(label: "On track", color: RTColor.good, description: "Near soft ~2000 kcal goal") }
            return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Met soft ~2000 kcal goal")
        case .hydration:
            if value < 1.5 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below soft hydration band") }
            if value < 2.0 { return MetricZone(label: "Building", color: RTColor.caution, description: "Approaching soft ~2.5 L goal") }
            if value < 2.5 { return MetricZone(label: "On track", color: RTColor.good, description: "Near soft ~2.5 L goal") }
            return MetricZone(label: "Hydrated", color: RTColor.optimal, description: "Met soft ~2.5 L hydration goal")
        case .caffeine:
            if value < 100 { return MetricZone(label: "Clear", color: RTColor.optimal, description: "Well under soft caffeine limit") }
            if value < 200 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Within soft ~200 mg band") }
            if value < 250 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "At or above soft caffeine limit") }
            return MetricZone(label: "High", color: RTColor.warning, description: "Above caution caffeine band")
        case .toothbrushing:
            if value <= 0 { return MetricZone(label: "Missed", color: RTColor.warning, description: "No brushing logged") }
            if value < 2 { return MetricZone(label: "Light", color: RTColor.caution, description: "Below soft hygiene band") }
            if value < 4 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~4 min goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~4 min brushing goal")
        case .handwashing:
            if value <= 0 { return MetricZone(label: "Missed", color: RTColor.warning, description: "No handwashing logged") }
            if value < 0.5 { return MetricZone(label: "Light", color: RTColor.caution, description: "Below soft hygiene band") }
            if value < 1.0 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft wash goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft handwashing goal")
        case .dietaryCarbs:
            if value < 112 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below soft ~225 g carb band") }
            if value < 169 { return MetricZone(label: "Building", color: RTColor.caution, description: "Approaching soft carb goal") }
            if value < 225 { return MetricZone(label: "On track", color: RTColor.good, description: "Near soft ~225 g carb goal") }
            return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Met soft ~225 g carb goal")
        case .dietaryFat:
            if value < 35 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below soft ~70 g fat band") }
            if value < 52 { return MetricZone(label: "Building", color: RTColor.caution, description: "Approaching soft fat goal") }
            if value < 70 { return MetricZone(label: "On track", color: RTColor.good, description: "Near soft ~70 g fat goal") }
            return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Met soft ~70 g fat goal")
        case .dietaryFiber:
            if value < 15 { return MetricZone(label: "Low", color: RTColor.warning, description: "Below soft ~30 g fiber band") }
            if value < 22 { return MetricZone(label: "Building", color: RTColor.caution, description: "Approaching soft fiber goal") }
            if value < 30 { return MetricZone(label: "On track", color: RTColor.good, description: "Near soft ~30 g fiber goal") }
            return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Met soft ~30 g fiber goal")
        case .dietarySugar:
            if value >= 75 { return MetricZone(label: "High", color: RTColor.warning, description: "Above soft ~50 g sugar limit") }
            if value >= 50 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "At or above soft sugar limit") }
            if value >= 25 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Within moderate sugar band") }
            return MetricZone(label: "Clear", color: RTColor.optimal, description: "Well under soft ~50 g sugar limit")
        case .dietarySodium:
            if value >= 3000 { return MetricZone(label: "High", color: RTColor.warning, description: "Above soft ~2300 mg sodium limit") }
            if value >= 2300 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "At or above soft sodium limit") }
            if value >= 1150 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Within moderate sodium band") }
            return MetricZone(label: "Clear", color: RTColor.optimal, description: "Well under soft ~2300 mg sodium limit")
        case .dietaryPotassium:
            if value < 1360 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft potassium band") }
            if value < 2500 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building potassium floor") }
            if value < 3400 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~3400 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~3400 mg potassium goal")
        case .dietaryCholesterol:
            if value >= 400 { return MetricZone(label: "High", color: RTColor.warning, description: "Above soft ~300 mg cholesterol limit") }
            if value >= 300 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "At or above soft cholesterol limit") }
            if value >= 150 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Within moderate cholesterol band") }
            return MetricZone(label: "Clear", color: RTColor.optimal, description: "Well under soft ~300 mg cholesterol limit")
        case .dietaryVitaminC:
            if value < 36 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin C band") }
            if value < 60 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin C floor") }
            if value < 90 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~90 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~90 mg vitamin C goal")
        case .dietaryVitaminD:
            if value < 240 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin D band") }
            if value < 400 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin D floor") }
            if value < 600 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~600 IU goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~600 IU vitamin D goal")
        case .dietaryVitaminB12:
            if value < 0.96 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin B12 band") }
            if value < 1.5 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin B12 floor") }
            if value < 2.4 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~2.4 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~2.4 mcg vitamin B12 goal")
        case .dietaryIron:
            if value < 7.2 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft iron band") }
            if value < 10 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building iron floor") }
            if value < 18 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~18 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~18 mg iron goal")
        case .dietaryCalcium:
            if value < 400 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft calcium band") }
            if value < 700 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building calcium floor") }
            if value < 1000 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~1000 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~1000 mg calcium goal")
        case .dietaryMagnesium:
            if value < 160 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft magnesium band") }
            if value < 280 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building magnesium floor") }
            if value < 400 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~400 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~400 mg magnesium goal")
        case .dietaryZinc:
            if value < 4.4 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft zinc band") }
            if value < 7 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building zinc floor") }
            if value < 11 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~11 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~11 mg zinc goal")
        case .dietaryFolate:
            if value < 160 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft folate band") }
            if value < 280 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building folate floor") }
            if value < 400 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~400 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~400 mcg folate goal")
        case .dietaryVitaminA:
            if value < 360 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin A band") }
            if value < 630 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin A floor") }
            if value < 900 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~900 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~900 mcg vitamin A goal")
        case .dietaryVitaminE:
            if value < 6 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin E band") }
            if value < 10 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin E floor") }
            if value < 15 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~15 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~15 mg vitamin E goal")
        case .dietaryVitaminK:
            if value < 48 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin K band") }
            if value < 84 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin K floor") }
            if value < 120 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~120 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~120 mcg vitamin K goal")
        case .dietaryVitaminB6:
            if value < 0.68 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft vitamin B6 band") }
            if value < 1.1 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building vitamin B6 floor") }
            if value < 1.7 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~1.7 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~1.7 mg vitamin B6 goal")
        case .dietaryThiamin:
            if value < 0.48 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Thiamin band") }
            if value < 0.8 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Thiamin floor") }
            if value < 1.2 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~1.2 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~1.2 mg Thiamin goal")
        case .dietaryRiboflavin:
            if value < 0.52 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Riboflavin band") }
            if value < 0.9 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Riboflavin floor") }
            if value < 1.3 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~1.3 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~1.3 mg Riboflavin goal")
        case .dietaryNiacin:
            if value < 6.4 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Niacin band") }
            if value < 11 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Niacin floor") }
            if value < 16 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~16 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~16 mg Niacin goal")
        case .dietaryPhosphorus:
            if value < 280 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Phosphorus band") }
            if value < 500 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Phosphorus floor") }
            if value < 700 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~700 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~700 mg Phosphorus goal")
        case .dietarySelenium:
            if value < 22 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Selenium band") }
            if value < 40 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Selenium floor") }
            if value < 55 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~55 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~55 mcg Selenium goal")
        case .dietaryCopper:
            if value < 0.36 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Copper band") }
            if value < 0.6 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Copper floor") }
            if value < 0.9 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~0.9 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~0.9 mg Copper goal")
        case .dietaryManganese:
            if value < 0.92 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Manganese band") }
            if value < 1.6 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Manganese floor") }
            if value < 2.3 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~2.3 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~2.3 mg Manganese goal")
        case .dietaryBiotin:
            if value < 12 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Biotin band") }
            if value < 20 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Biotin floor") }
            if value < 30 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~30 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~30 mcg Biotin goal")
        case .dietaryPantothenicAcid:
            if value < 2 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Pantothenic Acid band") }
            if value < 3.5 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Pantothenic Acid floor") }
            if value < 5 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~5 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~5 mg Pantothenic Acid goal")
        case .dietaryChloride:
            if value < 920 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Chloride band") }
            if value < 1800 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Chloride floor") }
            if value < 2300 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~2300 mg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~2300 mg Chloride goal")
        case .dietaryChromium:
            if value < 14 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Chromium band") }
            if value < 25 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Chromium floor") }
            if value < 35 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~35 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~35 mcg Chromium goal")
        case .dietaryMolybdenum:
            if value < 18 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Molybdenum band") }
            if value < 30 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Molybdenum floor") }
            if value < 45 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~45 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~45 mcg Molybdenum goal")
        case .dietaryIodine:
            if value < 60 { return MetricZone(label: "Very low", color: RTColor.warning, description: "Below soft Iodine band") }
            if value < 100 { return MetricZone(label: "Low", color: RTColor.caution, description: "Below building Iodine floor") }
            if value < 150 { return MetricZone(label: "Building", color: RTColor.good, description: "Approaching soft ~150 mcg goal") }
            return MetricZone(label: "Met", color: RTColor.optimal, description: "Met soft ~150 mcg Iodine goal")
        case .dietarySatFat:
            if value >= 30 { return MetricZone(label: "High", color: RTColor.warning, description: "High vs soft ~20 g Saturated Fat limit") }
            if value >= 20 { return MetricZone(label: "Elevated", color: RTColor.caution, description: "Elevated vs soft ~20 g Saturated Fat limit") }
            if value >= 10 { return MetricZone(label: "Moderate", color: RTColor.good, description: "Moderate vs soft ~20 g Saturated Fat limit") }
            return MetricZone(label: "Clear", color: RTColor.optimal, description: "Clear vs soft ~20 g Saturated Fat limit")
        case .dietaryMufa:
            if value >= 25 { return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Goal met vs soft ~25 g Monounsaturated Fat goal") }
            if value >= 18.75 { return MetricZone(label: "On track", color: RTColor.good, description: "On track vs soft ~25 g Monounsaturated Fat goal") }
            if value >= 12.5 { return MetricZone(label: "Building", color: RTColor.caution, description: "Building vs soft ~25 g Monounsaturated Fat goal") }
            return MetricZone(label: "Low", color: RTColor.warning, description: "Low vs soft ~25 g Monounsaturated Fat goal")
        case .dietaryPufa:
            if value >= 15 { return MetricZone(label: "Goal met", color: RTColor.optimal, description: "Goal met vs soft ~15 g Polyunsaturated Fat goal") }
            if value >= 11.25 { return MetricZone(label: "On track", color: RTColor.good, description: "On track vs soft ~15 g Polyunsaturated Fat goal") }
            if value >= 7.5 { return MetricZone(label: "Building", color: RTColor.caution, description: "Building vs soft ~15 g Polyunsaturated Fat goal") }
            return MetricZone(label: "Low", color: RTColor.warning, description: "Low vs soft ~15 g Polyunsaturated Fat goal")
        case .cyclingDistance:
            if value >= 40 { return MetricZone(label: "Long", color: RTColor.optimal, description: "Long vs soft ~40 km Cycling Distance goal") }
            if value >= 20 { return MetricZone(label: "Solid", color: RTColor.good, description: "Solid vs soft ~40 km Cycling Distance goal") }
            if value >= 8 { return MetricZone(label: "Light", color: RTColor.caution, description: "Light vs soft ~40 km Cycling Distance goal") }
            return MetricZone(label: "Low", color: RTColor.warning, description: "Low vs soft ~40 km Cycling Distance goal")
        case .cyclingSpeed:
            if value >= 8 { return MetricZone(label: "Brisk", color: RTColor.optimal, description: "Brisk vs soft ~8 m/s Cycling Speed goal") }
            if value >= 6 { return MetricZone(label: "Steady", color: RTColor.good, description: "Steady vs soft ~8 m/s Cycling Speed goal") }
            if value >= 4 { return MetricZone(label: "Easy", color: RTColor.caution, description: "Easy vs soft ~8 m/s Cycling Speed goal") }
            return MetricZone(label: "Slow", color: RTColor.warning, description: "Slow vs soft ~8 m/s Cycling Speed goal")
        }
    }
}

struct MetricZone {
    let label: String
    let color: Color
    let description: String
}
