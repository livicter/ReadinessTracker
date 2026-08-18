import SwiftUI

// MARK: - Color Palette (Dark Mode First)
enum RTColor {
    static let background = Color(hex: "0A0A0A")
    static let surface = Color(hex: "1C1C1E")
    static let surfaceElevated = Color(hex: "2C2C2E")
    static let surfaceHighlight = Color(hex: "3A3A3C")
    static let surfaceBorder = Color.white.opacity(0.06)
    
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "98989D")
    // iOS systemGray (dark) — 4.9:1 on `surface`, meets WCAG AA for small caption text
    static let tertiaryText = Color(hex: "8E8E93")
    
    // Zone colors - Apple system colors
    static let optimal = Color(hex: "30D158")
    static let good = Color(hex: "5AE88A")
    static let caution = Color(hex: "FF9F0A")
    static let warning = Color(hex: "FF453A")
    
    // Metric accent colors
    static let sleep = Color(hex: "5E5CE6")
    static let hrv = Color(hex: "30D158")
    static let recovery = Color(hex: "FF9F0A")
    static let strain = Color(hex: "FF453A")
    static let consistency = Color(hex: "BF5AF2")
    
    static let divider = Color.white.opacity(0.06)
    
    // App background gradient tokens (Apple Health style)
    static let appBackgroundTop = Color.black
    static let appBackgroundBottom = RTColor.background
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
        case .optimal: return "Ready to perform"
        case .good: return "Good to go"
        case .caution: return "Take it easy"
        case .warning: return "Rest needed"
        }
    }
    
    var glowColor: Color {
        color.opacity(0.3)
    }
}
