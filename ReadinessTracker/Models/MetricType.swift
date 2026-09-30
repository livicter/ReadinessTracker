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
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .sleep, .hrv, .activeCalories, .bloodOxygen, .steps, .flightsClimbed, .walkingDistance, .exerciseTime, .standHours, .standTime, .moveTime, .basalEnergy: return true
        case .restingHR, .respiratoryRate, .skinTemperature: return false
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
        }
    }
}

struct MetricZone {
    let label: String
    let color: Color
    let description: String
}
