import SwiftUI

enum MetricType: String, CaseIterable {
    case sleep = "Sleep"
    case hrv = "HRV"
    case restingHR = "Resting HR"
    case activeCalories = "Active Calories"
    case bloodOxygen = "Blood Oxygen"

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .hrv: return "waveform.path.ecg"
        case .restingHR: return "heart.fill"
        case .activeCalories: return "flame.fill"
        case .bloodOxygen: return "drop.fill"
        }
    }

    var unit: String {
        switch self {
        case .sleep: return "h"
        case .hrv: return "ms"
        case .restingHR: return "bpm"
        case .activeCalories: return "cal"
        case .bloodOxygen: return "%"
        }
    }

    var color: Color {
        switch self {
        case .sleep: return RTColor.sleep
        case .hrv: return RTColor.hrv
        case .restingHR: return RTColor.strain
        case .activeCalories: return RTColor.caution
        case .bloodOxygen: return RTColor.optimal
        }
    }

    var higherIsBetter: Bool {
        switch self {
        case .sleep, .hrv, .activeCalories, .bloodOxygen: return true
        case .restingHR: return false
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
        }
    }
}

struct MetricZone {
    let label: String
    let color: Color
    let description: String
}
