//
//  Readiness.swift
//  Readiness
//
//  Created by 🦭 Victor on 6/6/2026.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ReadinessEntry: TimelineEntry {
    let date: Date
    let score: Int
    let sleepHours: Double
    let hrv: Int
    let rhr: Int
}

// MARK: - Provider
struct ReadinessProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadinessEntry {
        ReadinessEntry(date: Date(), score: 75, sleepHours: 7.5, hrv: 45, rhr: 58)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadinessEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadinessEntry>) -> Void) {
        let entry = loadEntry()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func loadEntry() -> ReadinessEntry {
        #if targetEnvironment(simulator)
        return ReadinessEntry(date: Date(), score: 78, sleepHours: 7.5, hrv: 45, rhr: 58)
        #else
        guard let defaults = UserDefaults(suiteName: "group.com.readinesstracker") else {
            return ReadinessEntry(date: Date(), score: 50, sleepHours: 0, hrv: 0, rhr: 0)
        }
        let score = defaults.integer(forKey: "readinessScore")
        let hrv = defaults.integer(forKey: "hrv")
        let rhr = defaults.integer(forKey: "rhr")
        let sleepHours = defaults.double(forKey: "sleepHours")
        return ReadinessEntry(date: Date(), score: score, sleepHours: sleepHours, hrv: hrv, rhr: rhr)
        #endif
    }
}

// MARK: - Score Color
private func scoreColor(_ score: Int) -> Color {
    switch score {
    case 80...100: return .green
    case 60..<80: return .yellow
    case 40..<60: return .orange
    default: return .red
    }
}

// MARK: - Main Entry View
struct ReadinessEntryView: View {
    var entry: ReadinessEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(score: entry.score)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryCorner:
            CornerView(score: entry.score)
        case .accessoryInline:
            InlineView(score: entry.score)
        default:
            Text("\(entry.score)")
        }
    }
}

// MARK: - Circular (Small Ring)
struct CircularView: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(scoreColor(score).opacity(0.15), lineWidth: 10)

            Circle()
                .trim(from: 0, to: Double(score) / 100)
                .stroke(
                    scoreColor(score),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
        }
    }
}

// MARK: - Rectangular (Metrics Row)
struct RectangularView: View {
    let entry: ReadinessEntry

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(scoreColor(entry.score).opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: Double(entry.score) / 100)
                    .stroke(scoreColor(entry.score), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(entry.score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Readiness")
                    .font(.system(size: 12, weight: .semibold))

                if entry.sleepHours > 0 {
                    Text("\(String(format: "%.1f", entry.sleepHours))h sleep")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Corner (Ultra-wide, minimal)
struct CornerView: View {
    let score: Int

    var body: some View {
        ZStack {
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
struct InlineView: View {
    let score: Int

    var body: some View {
        Text("R:\(score)")
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundColor(scoreColor(score))
    }
}

// MARK: - Widget Configuration
struct Readiness: Widget {
    let kind: String = "Readiness"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadinessProvider()) { entry in
            ReadinessEntryView(entry: entry)
        }
        .configurationDisplayName("Readiness Score")
        .description("Shows your readiness score on your watch face")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

#Preview("Circular", as: .accessoryCircular) {
    Readiness()
} timeline: {
    ReadinessEntry(date: .now, score: 78, sleepHours: 7.5, hrv: 45, rhr: 58)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    Readiness()
} timeline: {
    ReadinessEntry(date: .now, score: 78, sleepHours: 7.5, hrv: 45, rhr: 58)
}
