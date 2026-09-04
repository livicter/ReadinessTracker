import SwiftUI

// MARK: - TrendDirection
enum TrendDirection: String, Codable {
    case up, down, flat
}

// MARK: - TrendPeriod
enum TrendPeriod: Int, CaseIterable {
    case week = 7
    case month = 30
    case quarter = 90
    case year = 365
}

// MARK: - Apple Native Design Tokens
// Inspired by Apple Health, Stocks, and Fitness apps
// Solid cards, capsule badges, SF Symbols, .continuous corner radius
// CANONICAL source for layout tokens — `RTLayout` (Theme.swift) forwards here.

enum AppleTheme {
    // Corner radii - Apple uses .continuous style
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 10
    
    // Spacing
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let horizontalMargin: CGFloat = 20
    
    // Typography - Apple Health style
    static let heroValue = Font.system(size: 56, weight: .semibold, design: .rounded)
    static let cardValue = Font.system(size: 32, weight: .semibold, design: .rounded)
    static let sectionHeader = Font.title3.weight(.bold)
    
    // Badge styling
    static let badgeBgOpacity: Double = 0.12
    static let badgeHPadding: CGFloat = 10
    static let badgeVPadding: CGFloat = 6
    
    // Card shadow tokens (Apple Health soft shadow)
    static let cardShadowOpacity: Double = 0.08
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 2
}

// MARK: - Native Card Style (Apple Health solid card)
struct NativeCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(AppleTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                    .fill(RTColor.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusLarge, style: .continuous)
                            .stroke(RTColor.surfaceBorder, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(AppleTheme.cardShadowOpacity), radius: AppleTheme.cardShadowRadius, x: 0, y: AppleTheme.cardShadowY)
            )
    }
}

// MARK: - Trend Badge (Apple Health style capsule)
struct TrendBadge: View {
    let direction: TrendDirection
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.systemImage)
                .font(.subheadline.weight(.semibold))
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(direction.color)
        .padding(.horizontal, AppleTheme.badgeHPadding)
        .padding(.vertical, AppleTheme.badgeVPadding)
        .background(direction.color.opacity(AppleTheme.badgeBgOpacity))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(direction.label) trend")
        .accessibilityValue(value)
    }
}

// MARK: - Compact Trend Indicator (for metric cards)
struct CompactTrendIndicator: View {
    let direction: TrendDirection
    let percentChange: Double?
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: direction.systemImage)
                .font(.caption.weight(.semibold))
            if let change = percentChange {
                Text("\(abs(change), specifier: "%.0f")%")
                    .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(direction.color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let change = percentChange {
            return "\(direction.label), \(Int(abs(change))) percent"
        }
        return direction.label
    }
}

// MARK: - Outlier Callout Row (Apple Health Highlights style)
struct OutlierCallout: View {
    enum OutlierType {
        case high, low, abnormal
        
        var icon: String {
            switch self {
            case .high: return "arrow.up.circle.fill"
            case .low: return "arrow.down.circle.fill"
            case .abnormal: return "exclamationmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .high: return .orange
            case .low: return .cyan
            case .abnormal: return .red
            }
        }
        
        var title: String {
            switch self {
            case .high: return "Above Average"
            case .low: return "Below Average"
            case .abnormal: return "Unusual Reading"
            }
        }
    }
    
    let type: OutlierType
    let value: String
    let date: String
    let deviation: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(type.color)
                .frame(width: 36, height: 36)
                .background(type.color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                
                Text("\(value) · \(date) · \(deviation)")
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surface)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Native Period Selector (deprecated alias - delegates to AppSegmentedControl)
struct NativePeriodSelector: View {
    @Binding var selectedPeriod: TrendPeriod

    var body: some View {
        AppSegmentedControl(options: TrendPeriod.allCases, selection: $selectedPeriod) { $0.label }
            .onChange(of: selectedPeriod) { _ in Haptic.selectionChanged() }
    }
}

// MARK: - Chart Annotation Tooltip (Apple native style)
struct ChartTooltip: View {
    let date: Date
    let value: String
    let unit: String
    let deviation: String?
    let isOutlier: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date, format: .dateTime.month(.abbreviated).day())
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(RTColor.primaryText)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            if let deviation = deviation {
                Text(deviation)
                    .font(.caption2)
                    .foregroundStyle(deviation.hasPrefix("+") ? RTColor.optimal : RTColor.warning)
            }
            
            if isOutlier {
                HStack(spacing: 2) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("Outlier")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RTColor.surface)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Stat Grid Item (Apple Health style)
struct StatGridItem: View {
    let label: String
    let value: String
    let unit: String
    let trend: TrendDirection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(RTColor.primaryText)
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(RTColor.secondaryText)
            }
            
            if let trend = trend {
                CompactTrendIndicator(direction: trend, percentChange: nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .fill(RTColor.surface)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Section Header (deprecated alias - delegates to AppSectionHeader)
struct NativeSectionHeader: View {
    let title: String
    let action: (() -> Void)?

    var body: some View {
        AppSectionHeader(title: title, action: action)
    }
}

// MARK: - App Section Header (Apple Health style)
struct AppSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(AppleTheme.sectionHeader)
                .foregroundStyle(RTColor.primaryText)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let action {
                Button(action: action) {
                    HStack(spacing: 4) {
                        Text("See All")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(RTColor.secondaryText)
                }
            }
        }
    }
}

// MARK: - App Segmented Control (Apple Health style)
struct AppSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection == option ? RTColor.primaryText : RTColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(RTColor.surfaceHighlight)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option ? .isSelected : [])
            }
        }
        .padding(4)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusSmall, style: .continuous))
    }
}

// MARK: - App Chip
/// Selected: dark text on surfaceHighlight, or white on a filled accent.
/// Never white on a light fill.
struct AppChip: View {
    let title: String
    var icon: String? = nil
    let selected: Bool
    var fill: Color? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
            }
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundStyle(foreground)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var foreground: Color {
        guard selected else { return RTColor.secondaryText }
        if let fill { return fill.contrastingTextColor }
        return RTColor.primaryText
    }

    private var background: Color {
        guard selected else { return .clear }
        return fill ?? RTColor.surfaceHighlight
    }
}

struct AppEmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(RTColor.tertiaryText)
            Text(title)
                .font(.headline)
                .foregroundStyle(RTColor.primaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RTColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct MissingMetricRow: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(RTColor.primaryText)
            Spacer()
            Text("Not recorded last night")
                .font(.caption)
                .foregroundStyle(RTColor.tertiaryText)
        }
        .padding(.horizontal, AppleTheme.cardPadding)
        .padding(.vertical, 12)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                .stroke(RTColor.surfaceBorder, lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), not recorded last night")
    }
}

// MARK: - App Stat Pill (Apple Health style)
struct AppStatPill: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    let trend: TrendDirection?

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)\(unit)")
                .font(AppleTheme.cardValue)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
            if let trend {
                CompactTrendIndicator(direction: trend, percentChange: nil)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RTColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - App Button (Apple Health style)
struct AppButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptic.press()
            action()
        }) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(color)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - TrendDirection Extension
extension TrendDirection {
    var systemImage: String {
        switch self {
        case .up: return "arrow.up.forward"
        case .down: return "arrow.down.forward"
        case .flat: return "arrow.forward"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return RTColor.optimal
        case .down: return RTColor.warning
        case .flat: return RTColor.tertiaryText
        }
    }
    
    var label: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .flat: return "Stable"
        }
    }
}

// MARK: - TrendPeriod Extension
extension TrendPeriod {
    var label: String {
        switch self {
        case .week: return "7D"
        case .month: return "30D"
        case .quarter: return "90D"
        case .year: return "1Y"
        }
    }
}
