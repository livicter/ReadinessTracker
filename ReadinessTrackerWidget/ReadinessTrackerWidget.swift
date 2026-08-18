import WidgetKit
import SwiftUI

struct ReadinessEntry: TimelineEntry {
    let date: Date
    let readinessScore: Int
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int
    let hrv: Int
    let rhr: Int
    let sleepHours: Double
}

struct Provider: TimelineProvider {
    static var sampleEntry: ReadinessEntry {
        ReadinessEntry(
            date: Date(),
            readinessScore: 78,
            gymScore: 82,
            workScore: 75,
            sleepScore: 80,
            hrv: 45,
            rhr: 58,
            sleepHours: 7.5
        )
    }

    func placeholder(in context: Context) -> ReadinessEntry {
        Self.sampleEntry
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        // Load from shared UserDefaults or App Group
        let entry = loadLatestEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }
    
    private func loadLatestEntry() -> ReadinessEntry {
        // Try to load from shared storage
        guard let defaults = UserDefaults(suiteName: "group.com.readinesstracker"),
              defaults.object(forKey: "readinessScore") != nil else {
            return Self.sampleEntry
        }
        return ReadinessEntry(
            date: Date(),
            readinessScore: defaults.integer(forKey: "readinessScore"),
            gymScore: defaults.integer(forKey: "gymScore"),
            workScore: defaults.integer(forKey: "workScore"),
            sleepScore: defaults.integer(forKey: "sleepScore"),
            hrv: defaults.integer(forKey: "hrv"),
            rhr: defaults.integer(forKey: "rhr"),
            sleepHours: defaults.double(forKey: "sleepHours")
        )
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: ReadinessEntry
    
    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 8) {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: Double(entry.readinessScore) / 100)
                        .stroke(
                            scoreColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(entry.readinessScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 80, height: 80)
                
                Text("Readiness")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var scoreColor: Color {
        switch entry.readinessScore {
        case 80...100: return Color.green
        case 60..<80: return Color.yellow
        default: return Color.red
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: ReadinessEntry
    
    var body: some View {
        ZStack {
            Color.black
            
            HStack(spacing: 16) {
                // Left: Main score
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 10)
                        
                        Circle()
                            .trim(from: 0, to: Double(entry.readinessScore) / 100)
                            .stroke(
                                scoreColor,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(entry.readinessScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(width: 90, height: 90)
                    
                    Text("Readiness")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                // Right: Breakdown
                VStack(alignment: .leading, spacing: 10) {
                    ScoreRow(label: "Gym", score: entry.gymScore, color: .orange)
                    ScoreRow(label: "Work", score: entry.workScore, color: .cyan)
                    ScoreRow(label: "Sleep", score: entry.sleepScore, color: .purple)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    HStack(spacing: 12) {
                        MetricMini(label: "HRV", value: "\(entry.hrv)", unit: "ms")
                        MetricMini(label: "RHR", value: "\(entry.rhr)", unit: "bpm")
                        MetricMini(label: "Sleep", value: String(format: "%.1f", entry.sleepHours), unit: "h")
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var scoreColor: Color {
        switch entry.readinessScore {
        case 80...100: return Color.green
        case 60..<80: return Color.yellow
        default: return Color.red
        }
    }
}

struct ScoreRow: View {
    let label: String
    let score: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 40, alignment: .leading)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                }
            }
            .frame(height: 6)
            
            Text("\(score)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 28, alignment: .trailing)
        }
    }
}

struct MetricMini: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Widget Configuration
@main
struct ReadinessTrackerWidget: Widget {
    let kind: String = "ReadinessTrackerWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                ReadinessWidgetView(entry: entry)
                    .containerBackground(.black, for: .widget)
            } else {
                ReadinessWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Readiness Score")
        .description("Track your daily readiness for gym and work.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ReadinessWidgetView: View {
    let entry: ReadinessEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
