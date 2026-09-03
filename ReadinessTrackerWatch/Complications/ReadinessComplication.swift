#if os(watchOS)
// NOTE: This complication was written against the iOS app target's stores
// (DataStore/MetadataStore) and a duplicate @main, so it cannot compile in this
// iOS wrapper target. It belongs in a watchOS widget extension target fed by
// WatchConnectivity snapshots. Excluded from compilation until migrated.
import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ReadinessEntry: TimelineEntry {
    let date: Date
    let score: Int
    let hasCheckIn: Bool
    let sleepHours: Double
    let hrv: Int
    let rhr: Int
}

// MARK: - Provider
struct ReadinessComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadinessEntry {
        ReadinessEntry(date: Date(), score: 75, hasCheckIn: false, sleepHours: 7.5, hrv: 45, rhr: 58)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        let entry = ReadinessEntry(date: Date(), score: 75, hasCheckIn: false, sleepHours: 7.5, hrv: 45, rhr: 58)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        
        let dataStore = DataStore.shared
        let metadataStore = MetadataStore.shared
        let data = dataStore.latest(for: .appleWatch)
        let score = data?.readinessScore ?? 50
        let hasCheckIn = metadataStore.hasCheckedInToday(.morning)
        
        let entry = ReadinessEntry(
            date: currentDate,
            score: score,
            hasCheckIn: hasCheckIn,
            sleepHours: data?.sleepHours ?? 0,
            hrv: Int(data?.hrv ?? 0),
            rhr: Int(data?.restingHeartRate ?? 0)
        )
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Score Color (shared)
private func scoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: return Color(hex: "00D084")
    case 60..<80: return Color(hex: "34C759")
    case 40..<60: return Color(hex: "FF9500")
    default: return Color(hex: "FF3B30")
    }
}

// MARK: - Main Entry View
struct ReadinessComplicationEntryView: View {
    var entry: ReadinessEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplication(score: entry.score, hasCheckIn: entry.hasCheckIn)
        case .accessoryRectangular:
            RectangularComplication(score: entry.score, hasCheckIn: entry.hasCheckIn, sleepHours: entry.sleepHours)
        case .accessoryCorner:
            CornerComplication(score: entry.score)
        case .accessoryInline:
            InlineComplication(score: entry.score, hasCheckIn: entry.hasCheckIn)
        case .accessoryCircular:
            GraphicCircularComplication(score: entry.score, hasCheckIn: entry.hasCheckIn)
        case .accessoryRectangular:
            GraphicRectangularComplication(entry: entry)
        default:
            Text("\(entry.score)")
        }
    }
}

// MARK: - Circular (Small Ring)
struct CircularComplication: View {
    let score: Int
    let hasCheckIn: Bool
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(scoreColor(score).opacity(0.15), lineWidth: 10)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    scoreColor(score),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor(score).opacity(0.4), radius: 3)
            
            // Score
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                
                // Check-in dot
                if !hasCheckIn {
                    Circle()
                        .fill(Color(hex: "FF9500"))
                        .frame(width: 6, height: 6)
                        .shadow(color: Color(hex: "FF9500").opacity(0.5), radius: 2)
                }
            }
        }
    }
}

// MARK: - Rectangular (Metrics Row)
struct RectangularComplication: View {
    let score: Int
    let hasCheckIn: Bool
    let sleepHours: Double
    
    var body: some View {
        HStack(spacing: 8) {
            // Score ring (compact)
            ZStack {
                Circle()
                    .stroke(scoreColor(score).opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .frame(width: 36, height: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Readiness")
                    .font(.system(size: 12, weight: .semibold))
                
                if sleepHours > 0 {
                    Text("\(String(format: "%.1f", sleepHours))h sleep")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                if !hasCheckIn {
                    Text("Check-in pending")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(hex: "FF9500"))
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Corner (Ultra-wide, minimal)
struct CornerComplication: View {
    let score: Int
    
    var body: some View {
        ZStack {
            // Corner arc (top-right quadrant style)
            Circle()
                .trim(from: 0.75, to: 0.75 + (Double(score) / 100) * 0.5)
                .stroke(scoreColor(score), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(score)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor(score))
        }
    }
}

// MARK: - Inline (Minimal text)
struct InlineComplication: View {
    let score: Int
    let hasCheckIn: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text("R:\(score)")
                .font(.system(.body, design: .rounded).weight(.semibold))
            
            if !hasCheckIn {
                Circle()
                    .fill(Color(hex: "FF9500"))
                    .frame(width: 6, height: 6)
            }
        }
        .foregroundColor(scoreColor(score))
    }
}

// MARK: - Graphic Circular (Large, detailed)
struct GraphicCircularComplication: View {
    let score: Int
    let hasCheckIn: Bool
    
    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(scoreColor(score).opacity(0.2), lineWidth: 14)
            
            // Progress arc with glow
            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    scoreColor(score),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: scoreColor(score).opacity(0.5), radius: 4)
            
            // Inner content
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(zoneLabel(score))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                if !hasCheckIn {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color(hex: "FF9500"))
                            .frame(width: 5, height: 5)
                        Text("Check-in")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "FF9500"))
                    }
                    .padding(.top, 2)
                }
            }
        }
    }
    
    private func zoneLabel(_ score: Int) -> String {
        switch score {
        case 80...100: return "Ready"
        case 60..<80: return "Good"
        case 40..<60: return "Easy"
        default: return "Rest"
        }
    }
}

// MARK: - Graphic Rectangular (Full metrics)
struct GraphicRectangularComplication: View {
    let entry: ReadinessEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Score ring
            ZStack {
                Circle()
                    .stroke(scoreColor(entry.score).opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: Double(entry.score) / 100)
                    .stroke(scoreColor(entry.score), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(entry.score)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("R")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 56, height: 56)
            
            // Right: Metrics
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    MetricBadge(icon: "bed.double.fill", value: "\(String(format: "%.1f", entry.sleepHours))h", color: Color(hex: "5E5CE6"))
                    MetricBadge(icon: "waveform.path.ecg", value: "\(entry.hrv)", color: Color(hex: "00D084"))
                    MetricBadge(icon: "heart.fill", value: "\(entry.rhr)", color: Color(hex: "FF3B30"))
                }
                
                if !entry.hasCheckIn {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "FF9500"))
                        Text("Morning check-in pending")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(hex: "FF9500"))
                    }
                    .padding(.top, 2)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct MetricBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
    }
}

// MARK: - Widget Configuration
@main
struct ReadinessComplication: Widget {
    let kind: String = "ReadinessComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessComplicationProvider()) { entry in
            ReadinessComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Readiness Score")
        .description("Shows your readiness score with sleep, HRV, and RHR metrics")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}
#endif
