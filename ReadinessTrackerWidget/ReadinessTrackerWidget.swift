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

    /// Match Today `TripleRingHero` / `RTColor` (Gym=strain, Work=hrv, Sleep=sleep).
    static let gym = Color(red: 255/255, green: 59/255, blue: 48/255)    // FF3B30
    static let work = Color(red: 52/255, green: 199/255, blue: 89/255)   // 34C759
    static let sleep = Color(red: 88/255, green: 86/255, blue: 214/255)  // 5856D6

    static func score(_ score: Int) -> Color {
        switch score {
        case 80...100: return Color(red: 52/255, green: 199/255, blue: 89/255)   // systemGreen light
        case 60..<80: return Color(red: 255/255, green: 149/255, blue: 0/255)    // systemOrange
        default: return Color(red: 255/255, green: 59/255, blue: 48/255)         // systemRed
        }
    }
}




// MARK: - Deep links (Check-in Morning/Evening + Trends / History browse)
private enum WidgetDeepLink {
    static let checkIn = URL(string: "readinesstracker://checkin/morning")!
    static let checkInEvening = URL(string: "readinesstracker://checkin/evening")!
    static let trends = URL(string: "readinesstracker://trends")!
}

/// Fitness-style Check-in control for medium/large Home widgets.
private struct WidgetCheckInControl: View {
    var compact: Bool = false
    var evening: Bool = false

    var body: some View {
        Link(destination: evening ? WidgetDeepLink.checkInEvening : WidgetDeepLink.checkIn) {
            HStack(spacing: 4) {
                Image(systemName: evening ? "moon.stars.fill" : "checkmark.circle.fill")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
                Text(evening ? "Evening" : "Check-in")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        evening
                            ? Color(red: 88/255, green: 86/255, blue: 214/255) // systemIndigo / sleep
                            : Color(red: 52/255, green: 199/255, blue: 89/255) // systemGreen
                    )
            )
        }
        .accessibilityLabel(evening ? "Open Evening Check-in" : "Open Check-in")
    }
}

/// Secondary Trends control → History browse (`readinesstracker://trends`).
private struct WidgetTrendsControl: View {
    var compact: Bool = false

    var body: some View {
        Link(destination: WidgetDeepLink.trends) {
            HStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
                Text("Trends")
                    .font(.system(size: compact ? 11 : 12, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color(red: 0/255, green: 122/255, blue: 255/255)) // systemBlue
            )
        }
        .accessibilityLabel("Open Trends")
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        VStack(spacing: 6) {
            CompactTripleRingsView(
                gymScore: entry.gymScore,
                workScore: entry.workScore,
                sleepScore: entry.sleepScore,
                size: 96,
                gymColor: WidgetTone.gym,
                workColor: WidgetTone.work,
                sleepColor: WidgetTone.sleep,
                valueColor: WidgetTone.value,
                captionColor: WidgetTone.label
            )
            Text("Readiness")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetTone.label)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.checkIn)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                CompactTripleRingsView(
                    gymScore: entry.gymScore,
                    workScore: entry.workScore,
                    sleepScore: entry.sleepScore,
                    size: 100,
                    showsCaption: true,
                    gymColor: WidgetTone.gym,
                    workColor: WidgetTone.work,
                    sleepColor: WidgetTone.sleep,
                    valueColor: WidgetTone.value,
                    captionColor: WidgetTone.label
                )
                Text("Readiness")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(WidgetTone.label)
            }

            VStack(alignment: .leading, spacing: 8) {
                ScoreRow(label: "Gym", score: entry.gymScore, color: WidgetTone.gym)
                ScoreRow(label: "Work", score: entry.workScore, color: WidgetTone.work)
                ScoreRow(label: "Sleep", score: entry.sleepScore, color: WidgetTone.sleep)

                Divider()

                HStack(spacing: 8) {
                    MetricMini(label: "HRV", value: "\(entry.hrv)", unit: "ms")
                    MetricMini(label: "RHR", value: "\(entry.rhr)", unit: "bpm")
                    Spacer(minLength: 0)
                    WidgetTrendsControl(compact: true)
                    WidgetCheckInControl(compact: true)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.checkIn)
    }
}


// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                CompactTripleRingsView(
                    gymScore: entry.gymScore,
                    workScore: entry.workScore,
                    sleepScore: entry.sleepScore,
                    size: 120,
                    showsCaption: true,
                    gymColor: WidgetTone.gym,
                    workColor: WidgetTone.work,
                    sleepColor: WidgetTone.sleep,
                    valueColor: WidgetTone.value,
                    captionColor: WidgetTone.label
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Readiness")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WidgetTone.label)
                    Text("\(entry.readinessScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTone.value)
                        .monospacedDigit()
                    Text("Gym · Work · Sleep")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetTone.label)
                    HStack(spacing: 6) {
                        WidgetCheckInControl()
                        WidgetCheckInControl(evening: true)
                    }
                    .padding(.top, 4)
                    WidgetTrendsControl()
                }
                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                ScoreRow(label: "Gym", score: entry.gymScore, color: WidgetTone.gym)
                ScoreRow(label: "Work", score: entry.workScore, color: WidgetTone.work)
                ScoreRow(label: "Sleep", score: entry.sleepScore, color: WidgetTone.sleep)
            }

            Divider()

            HStack(spacing: 16) {
                MetricMini(label: "HRV", value: "\(entry.hrv)", unit: "ms")
                MetricMini(label: "RHR", value: "\(entry.rhr)", unit: "bpm")
                MetricMini(label: "Sleep", value: String(format: "%.1f", entry.sleepHours), unit: "h")
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetDeepLink.checkIn)
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



// MARK: - Extra Large Widget (iPad / StandBy)
/// Fitness / Health-style `.systemExtraLarge` glance: larger rings + Large rows/metrics
/// plus readiness cue and Gym/Work/Sleep metric tiles (richer than `.systemLarge`).
struct ExtraLargeWidgetView: View {
    let entry: ReadinessEntry

    private var readinessCue: String {
        switch entry.readinessScore {
        case 80...100: return "High"
        case 60..<80: return "Moderate"
        default: return "Low"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                CompactTripleRingsView(
                    gymScore: entry.gymScore,
                    workScore: entry.workScore,
                    sleepScore: entry.sleepScore,
                    size: 148,
                    showsCaption: true,
                    gymColor: WidgetTone.gym,
                    workColor: WidgetTone.work,
                    sleepColor: WidgetTone.sleep,
                    valueColor: WidgetTone.value,
                    captionColor: WidgetTone.label
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text("Readiness")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(WidgetTone.label)
                    Text("\(entry.readinessScore)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(WidgetTone.value)
                        .monospacedDigit()
                    Text(readinessCue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(WidgetTone.score(entry.readinessScore))
                    Text("Gym · Work · Sleep")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(WidgetTone.label)
                    HStack(spacing: 6) {
                        WidgetCheckInControl()
                        WidgetCheckInControl(evening: true)
                    }
                    .padding(.top, 4)
                    WidgetTrendsControl()
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    ScoreRow(label: "Gym", score: entry.gymScore, color: WidgetTone.gym)
                    ScoreRow(label: "Work", score: entry.workScore, color: WidgetTone.work)
                    ScoreRow(label: "Sleep", score: entry.sleepScore, color: WidgetTone.sleep)
                }

                Divider()

                HStack(spacing: 16) {
                    MetricMini(label: "HRV", value: "\(entry.hrv)", unit: "ms")
                    MetricMini(label: "RHR", value: "\(entry.rhr)", unit: "bpm")
                    MetricMini(label: "Sleep", value: String(format: "%.1f", entry.sleepHours), unit: "h")
                    Spacer(minLength: 0)
                }

                HStack(spacing: 16) {
                    MetricMini(label: "Gym", value: "\(entry.gymScore)", unit: "")
                    MetricMini(label: "Work", value: "\(entry.workScore)", unit: "")
                    MetricMini(label: "Sleep", value: "\(entry.sleepScore)", unit: "")
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(WidgetDeepLink.checkIn)
    }
}

// MARK: - Accessory Circular (Lock Screen)
@available(iOSApplicationExtension 16.0, *)
struct AccessoryCircularWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            CompactTripleRingsView(
                gymScore: entry.gymScore,
                workScore: entry.workScore,
                sleepScore: entry.sleepScore,
                size: side,
                showsCaption: false,
                minimumLineWidth: 3,
                gap: 1.5,
                gymColor: WidgetTone.gym,
                workColor: WidgetTone.work,
                sleepColor: WidgetTone.sleep,
                valueColor: WidgetTone.value,
                captionColor: WidgetTone.label
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Accessory Rectangular (Lock Screen)
@available(iOSApplicationExtension 16.0, *)
struct AccessoryRectangularWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                CompactTripleRingsView(
                    gymScore: entry.gymScore,
                    workScore: entry.workScore,
                    sleepScore: entry.sleepScore,
                    size: side,
                    showsCaption: false,
                    minimumLineWidth: 3,
                    gap: 1.5,
                    gymColor: WidgetTone.gym,
                    workColor: WidgetTone.work,
                    sleepColor: WidgetTone.sleep,
                    valueColor: WidgetTone.value,
                    captionColor: WidgetTone.label
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 64)

            VStack(alignment: .leading, spacing: 2) {
                Text("Readiness")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                Text("\(entry.readinessScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .monospacedDigit()
                HStack(spacing: 6) {
                    AccessoryCue(letter: "G", score: entry.gymScore, color: WidgetTone.gym)
                    AccessoryCue(letter: "W", score: entry.workScore, color: WidgetTone.work)
                    AccessoryCue(letter: "S", score: entry.sleepScore, color: WidgetTone.sleep)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
private struct AccessoryCue: View {
    let letter: String
    let score: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(letter)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
            Text("\(score)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .monospacedDigit()
        }
    }
}


// MARK: - Accessory Inline (Lock Screen)
@available(iOSApplicationExtension 16.0, *)
struct AccessoryInlineWidgetView: View {
    let entry: ReadinessEntry

    var body: some View {
        // Single-line Lock Screen glance beside the time: readiness + short G/W/S cues.
        Text("\(entry.readinessScore) · G\(entry.gymScore) W\(entry.workScore) S\(entry.sleepScore)")
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .monospacedDigit()
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
        .supportedFamilies({
            if #available(iOSApplicationExtension 16.0, *) {
                return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline]
            } else {
                return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
            }
        }())
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
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .systemExtraLarge:
            ExtraLargeWidgetView(entry: entry)
        case .accessoryCircular:
            if #available(iOSApplicationExtension 16.0, *) {
                AccessoryCircularWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        case .accessoryRectangular:
            if #available(iOSApplicationExtension 16.0, *) {
                AccessoryRectangularWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        case .accessoryInline:
            if #available(iOSApplicationExtension 16.0, *) {
                AccessoryInlineWidgetView(entry: entry)
            } else {
                SmallWidgetView(entry: entry)
            }
        default:
            SmallWidgetView(entry: entry)
        }
    }
}


