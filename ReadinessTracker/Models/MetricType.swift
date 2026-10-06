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
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .sleep, .hrv, .activeCalories, .bloodOxygen, .steps, .flightsClimbed, .walkingDistance, .exerciseTime, .standHours, .standTime, .moveTime, .basalEnergy, .wheelchairDistance, .bodyMass, .leanBodyMass, .vo2Max, .mindfulMinutes, .timeInDaylight, .heartRateRecovery, .wheelchairPushes, .peripheralPerfusion, .swimDistance, .envSoundReduction, .protein: return true
        case .restingHR, .respiratoryRate, .skinTemperature, .bodyFat, .waistCircumference, .bloodGlucose, .walkingHeartRate, .afBurden, .falls, .uvExposure, .environmentalAudio, .headphoneAudio: return false
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
        }
    }
}

struct MetricZone {
    let label: String
    let color: Color
    let description: String
}
