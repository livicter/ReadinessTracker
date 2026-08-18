import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// Shared colors/labels matching the iPhone app's palette.
enum WatchTheme {
    static let green = Color(hex: "00D084")
    static let lightGreen = Color(hex: "34C759")
    static let orange = Color(hex: "FF9500")
    static let red = Color(hex: "FF3B30")
    static let indigo = Color(hex: "5E5CE6")
    static let purple = Color(hex: "BF5AF2")
    static let teal = Color(hex: "64D2FF")

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return green
        case 60..<80: return lightGreen
        case 40..<60: return orange
        default: return red
        }
    }

    static func readinessLabel(_ score: Int) -> String {
        switch score {
        case 80...100: return "Ready"
        case 60..<80: return "Good"
        case 40..<60: return "Easy"
        default: return "Rest"
        }
    }

    /// Strain is WHOOP-style 0-21.
    static func strainColor(_ strain: Double) -> Color {
        switch strain {
        case 14...: return red
        case 10..<14: return orange
        default: return teal
        }
    }

    static func strainLabel(_ strain: Double) -> String {
        switch strain {
        case 18...: return "All Out"
        case 14..<18: return "High"
        case 10..<14: return "Moderate"
        case 5..<10: return "Light"
        default: return "Low"
        }
    }
}

/// Icon + label + value row used across watch pages.
struct WatchMetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
    }
}

/// Circular score ring with a centered value, sized for the watch canvas.
struct ScoreRing: View {
    let value: Double // 0-1
    let color: Color
    var lineWidth: CGFloat = 10

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(value, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: value)
        }
    }
}
