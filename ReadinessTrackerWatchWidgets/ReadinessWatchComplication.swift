import SwiftUI
import WidgetKit

/// Watch face complication (WidgetKit accessory families) with Fitness-style Gym/Work/Sleep rings.
/// Timeline reads the last `WatchSnapshot` dictionary from the App Group when provisioned;
/// falls back to sample scores so the extension always renders.

// MARK: - Entry

struct WatchComplicationEntry: TimelineEntry {
    let date: Date
    let readiness: Int
    let gymScore: Int
    let workScore: Int
    let sleepScore: Int

    static let sample = WatchComplicationEntry(
        date: Date(),
        readiness: 79,
        gymScore: 82,
        workScore: 75,
        sleepScore: 80
    )
}

// MARK: - Snapshot store (App Group ↔ Watch App)

enum WatchComplicationStore {
    static let appGroupID = "group.com.readinesstracker"
    static let snapshotKey = "lastWatchSnapshot"

    static func loadEntry(at date: Date = Date()) -> WatchComplicationEntry {
        let defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        guard let dict = defaults.dictionary(forKey: snapshotKey) else {
            return .sample
        }
        let gym = dict["gymScore"] as? Int ?? 0
        let work = dict["workScore"] as? Int ?? 0
        let sleep = dict["sleepScore"] as? Int ?? 0
        let readiness = dict["readiness"] as? Int
            ?? Int(((gym + work + sleep) / 3))
        return WatchComplicationEntry(
            date: date,
            readiness: readiness,
            gymScore: gym,
            workScore: work,
            sleepScore: sleep
        )
    }
}

// MARK: - Provider

struct WatchComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchComplicationEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (WatchComplicationEntry) -> Void) {
        completion(WatchComplicationStore.loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchComplicationEntry>) -> Void) {
        let entry = WatchComplicationStore.loadEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: entry.date) ?? entry.date.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Views

struct WatchCircularComplicationView: View {
    let entry: WatchComplicationEntry

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
                valueColor: .primary,
                captionColor: .secondary
            )
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct WatchRectangularComplicationView: View {
    let entry: WatchComplicationEntry

    private let gymColor = Color(red: 255/255, green: 59/255, blue: 48/255)
    private let workColor = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let sleepColor = Color(red: 88/255, green: 86/255, blue: 214/255)

    var body: some View {
        // Lock Screen rectangular parity (#33): compact triple rings + readiness + short G/W/S cues.
        HStack(spacing: 6) {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                CompactTripleRingsView(
                    gymScore: entry.gymScore,
                    workScore: entry.workScore,
                    sleepScore: entry.sleepScore,
                    size: side,
                    showsCaption: false,
                    minimumLineWidth: 2.5,
                    gap: 1,
                    gymColor: gymColor,
                    workColor: workColor,
                    sleepColor: sleepColor,
                    valueColor: .primary,
                    captionColor: .secondary
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 44)

            VStack(alignment: .leading, spacing: 1) {
                Text("Readiness")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(entry.readiness)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 4) {
                    WatchAccessoryCue(letter: "G", score: entry.gymScore, color: gymColor)
                    WatchAccessoryCue(letter: "W", score: entry.workScore, color: workColor)
                    WatchAccessoryCue(letter: "S", score: entry.sleepScore, color: sleepColor)
                }
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

private struct WatchAccessoryCue: View {
    let letter: String
    let score: Int
    let color: Color

    var body: some View {
        HStack(spacing: 1) {
            Text(letter)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(color)
            Text("\(score)")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

struct WatchInlineComplicationView: View {
    let entry: WatchComplicationEntry

    private let gymColor = Color(red: 255/255, green: 59/255, blue: 48/255)
    private let workColor = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let sleepColor = Color(red: 88/255, green: 86/255, blue: 214/255)
    private let readinessColor = Color(red: 10/255, green: 132/255, blue: 255/255)

    var body: some View {
        // Compact accessoryInline: colored readiness + short G/W/S cues (Lock #34 / rect #44 parity).
        HStack(spacing: 3) {
            Text("R\(entry.readiness)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(readinessColor)
                .monospacedDigit()
            WatchAccessoryCue(letter: "G", score: entry.gymScore, color: gymColor)
            WatchAccessoryCue(letter: "W", score: entry.workScore, color: workColor)
            WatchAccessoryCue(letter: "S", score: entry.sleepScore, color: sleepColor)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct WatchCornerComplicationView: View {
    let entry: WatchComplicationEntry

    private let gymColor = Color(red: 255/255, green: 59/255, blue: 48/255)
    private let workColor = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let sleepColor = Color(red: 88/255, green: 86/255, blue: 214/255)
    private let readinessColor = Color(red: 10/255, green: 132/255, blue: 255/255)

    var body: some View {
        // Compact rings (#44) + colored readiness/G/W/S widgetLabel cues (inline #45 parity).
        CompactTripleRingsView(
            gymScore: entry.gymScore,
            workScore: entry.workScore,
            sleepScore: entry.sleepScore,
            size: 28,
            showsCaption: false,
            minimumLineWidth: 2,
            gap: 0.8,
            gymColor: gymColor,
            workColor: workColor,
            sleepColor: sleepColor,
            valueColor: .primary,
            captionColor: .secondary
        )
        .widgetLabel {
            HStack(spacing: 2) {
                Text("R\(entry.readiness)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(readinessColor)
                    .monospacedDigit()
                WatchAccessoryCue(letter: "G", score: entry.gymScore, color: gymColor)
                WatchAccessoryCue(letter: "W", score: entry.workScore, color: workColor)
                WatchAccessoryCue(letter: "S", score: entry.sleepScore, color: sleepColor)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.55)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct WatchComplicationEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WatchComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            WatchCircularComplicationView(entry: entry)
        case .accessoryRectangular:
            WatchRectangularComplicationView(entry: entry)
        case .accessoryInline:
            WatchInlineComplicationView(entry: entry)
        case .accessoryCorner:
            WatchCornerComplicationView(entry: entry)
        default:
            WatchCircularComplicationView(entry: entry)
        }
    }
}

// MARK: - Widget + Bundle

struct ReadinessWatchComplication: Widget {
    let kind = "ReadinessWatchComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchComplicationProvider()) { entry in
            WatchComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Readiness Rings")
        .description("Fitness-style Gym, Work, and Sleep rings on your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCorner
        ])
    }
}

@main
struct ReadinessTrackerWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ReadinessWatchComplication()
    }
}
