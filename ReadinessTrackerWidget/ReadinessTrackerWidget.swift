import WidgetKit
import SwiftUI
import UIKit

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
        let entry = loadLatestEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }

    private func loadLatestEntry() -> ReadinessEntry {
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

// MARK: - Palette (Apple Health bright, widget-safe system colors)
private enum WidgetTone {
    static let track = Color.primary.opacity(0.08)
    static let label = Color.secondary
    static let value = Color.primary

    static func score(_ score: Int) -> Color {
        switch score {
        case 80...100: return Color(red: 52/255, green: 199/255, blue: 89/255)   // systemGreen light
        case 60..<80: return Color(red: 255/255, green: 149/255, blue: 0/255)    // systemOrange
        default: return Color(red: 255/255, green: 59/255, blue: 48/255)         // systemRed
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(WidgetTone.track, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: Double(entry.readinessScore) / 100)
                    .stroke(
                        WidgetTone.score(entry.readinessScore),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Text("\(entry.readinessScore)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTone.value)
                    .monospacedDigit()
            }
            .frame(width: 80, height: 80)

            Text("Readiness")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(WidgetTone.label)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(WidgetTone.track, lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: Double(entry.readinessScore) / 100)
                        .stroke(
                            WidgetTone.score(entry.readinessScore),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.readinessScore)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTone.value)
                        .monospacedDigit()
                }
                .frame(width: 90, height: 90)

                Text("Readiness")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTone.label)
            }

            VStack(alignment: .leading, spacing: 10) {
                ScoreRow(label: "Gym", score: entry.gymScore, color: Color(red: 255/255, green: 149/255, blue: 0/255))
                ScoreRow(label: "Work", score: entry.workScore, color: Color(red: 50/255, green: 173/255, blue: 230/255))
                ScoreRow(label: "Sleep", score: entry.sleepScore, color: Color(red: 88/255, green: 86/255, blue: 214/255))

                Divider()

                HStack(spacing: 12) {
                    MetricMini(label: "HRV", value: "\(entry.hrv)", unit: "ms")
                    MetricMini(label: "RHR", value: "\(entry.rhr)", unit: "bpm")
                    MetricMini(label: "Sleep", value: String(format: "%.1f", entry.sleepHours), unit: "h")
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .foregroundStyle(WidgetTone.label)
                .frame(width: 40, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(WidgetTone.track)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(score) / 100, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(score)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetTone.value)
                .monospacedDigit()
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
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(WidgetTone.label)

            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetTone.value)
                    .monospacedDigit()
                Text(unit)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(WidgetTone.label)
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
                    .containerBackground(for: .widget) {
                        Color(uiColor: .systemBackground)
                    }
            } else {
                ReadinessWidgetView(entry: entry)
                    .background(Color(uiColor: .systemBackground))
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
