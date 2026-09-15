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

    var body: some View {
        HStack(spacing: 6) {
            CompactTripleRingsView(
                gymScore: entry.gymScore,
                workScore: entry.workScore,
                sleepScore: entry.sleepScore,
                size: 36,
                showsCaption: false,
                minimumLineWidth: 2.5,
                gap: 1,
                valueColor: .primary,
                captionColor: .secondary
            )
            VStack(alignment: .leading, spacing: 1) {
                Text("Ready \(entry.readiness)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("G\(entry.gymScore) W\(entry.workScore) S\(entry.sleepScore)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct WatchInlineComplicationView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        Text("R\(entry.readiness) G\(entry.gymScore) W\(entry.workScore) S\(entry.sleepScore)")
            .font(.system(.body, design: .rounded).weight(.semibold))
            .monospacedDigit()
            .containerBackground(for: .widget) { Color.clear }
    }
}

struct WatchCornerComplicationView: View {
    let entry: WatchComplicationEntry

    var body: some View {
        Text("\(entry.readiness)")
            .font(.system(.title3, design: .rounded).weight(.bold))
            .monospacedDigit()
            .widgetLabel {
                Text("G\(entry.gymScore) W\(entry.workScore) S\(entry.sleepScore)")
                    .monospacedDigit()
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
