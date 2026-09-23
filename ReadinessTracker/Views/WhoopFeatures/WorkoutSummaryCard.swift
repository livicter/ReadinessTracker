import SwiftUI

/// WHOOP / Apple Fitness–style workout glance on Recovery & Strain.
/// Elevates sparse workout rows and uses fixture-seeded `StrainSession`s so UITests
/// leave the empty state (Honest #108).
struct WorkoutSummaryCard: View {
    let sessions: [StrainSession]
    let hrSamples: [HRSample]

    private var totalMinutes: Int {
        Int(sessions.map(\.durationMinutes).reduce(0, +).rounded())
    }

    private var totalTRIMP: Int {
        Int(sessions.map(\.trimp).reduce(0, +).rounded())
    }

    private var status: (label: String, color: Color) {
        guard !sessions.isEmpty else { return ("None", RTColor.secondaryText) }
        let load = sessions.map(\.trimp).reduce(0, +)
        if load >= 120 { return ("High load", RTColor.caution) }
        if load >= 60 { return ("Solid session", RTColor.good) }
        return ("Light load", RTColor.optimal)
    }

    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workouts")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(RTColor.primaryText)
                        Text(
                            sessions.isEmpty
                                ? "No recorded workouts"
                                : "\(sessions.count) session\(sessions.count == 1 ? "" : "s") · \(totalMinutes) min · \(totalTRIMP) TRIMP"
                        )
                        .font(.subheadline)
                        .foregroundStyle(RTColor.secondaryText)
                    }
                    Spacer(minLength: 8)
                    if !sessions.isEmpty {
                        Text(status.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(status.color)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(status.color.opacity(0.12))
                            .clipShape(Capsule())
                            .accessibilityLabel(status.label)
                    }
                }

                if !sessions.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                            sessionRow(session, index: index)
                        }
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(SurfaceID.strainWorkouts)
            .accessibilityLabel(sessions.isEmpty ? "Workouts none" : "Workouts \(status.label)")
        }
    }

    private func sessionRow(_ session: StrainSession, index: Int) -> some View {
        let tint = RTColor.strain
        let samples = hrSamples.filter {
            $0.timestamp >= session.startDate && $0.timestamp <= session.endDate
        }
        let avgHR: Int? = {
            guard !samples.isEmpty else { return nil }
            let sum = samples.map(\.bpm).reduce(0, +)
            return Int((sum / Double(samples.count)).rounded())
        }()
        let peakHR: Int? = samples.map(\.bpm).max().map { Int($0.rounded()) }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: iconName(for: session.workoutType))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.14))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.workoutType)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)
                    Text(timeRange(session))
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                }
                Spacer(minLength: 8)
                if session.contribution > 0 {
                    Text(String(format: "+%.1f", session.contribution))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(tint.opacity(0.12))
                        .clipShape(Capsule())
                        .accessibilityLabel(
                            "Strain contribution \(String(format: "%.1f", session.contribution))"
                        )
                }
            }

            HStack(spacing: 8) {
                metricChip(
                    icon: "timer",
                    label: "Duration",
                    value: "\(Int(session.durationMinutes.rounded()))",
                    unit: "min",
                    tint: tint,
                    surfaceID: index == 0
                        ? SurfaceID.strainWorkoutDuration
                        : "\(SurfaceID.strainWorkoutDuration).\(index)"
                )
                metricChip(
                    icon: "bolt.fill",
                    label: "TRIMP",
                    value: "\(Int(session.trimp.rounded()))",
                    unit: "",
                    tint: RTColor.caution,
                    surfaceID: index == 0
                        ? SurfaceID.strainWorkoutTRIMP
                        : "\(SurfaceID.strainWorkoutTRIMP).\(index)"
                )
                if let avgHR {
                    metricChip(
                        icon: "heart.fill",
                        label: peakHR.map { "Avg · peak \($0)" } ?? "Avg HR",
                        value: "\(avgHR)",
                        unit: "bpm",
                        tint: RTColor.good,
                        surfaceID: index == 0
                            ? SurfaceID.strainWorkoutHR
                            : "\(SurfaceID.strainWorkoutHR).\(index)"
                    )
                }
            }
        }
        .padding(12)
        .background(tint.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(
            index == 0
                ? SurfaceID.strainWorkoutSession
                : "\(SurfaceID.strainWorkoutSession).\(index)"
        )
        .accessibilityLabel(
            "\(session.workoutType), \(Int(session.durationMinutes.rounded())) minutes, \(Int(session.trimp.rounded())) TRIMP"
        )
    }

    private func metricChip(
        icon: String,
        label: String,
        value: String,
        unit: String,
        tint: Color,
        surfaceID: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 22, height: 22)
                    .background(tint.opacity(0.14))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RTColor.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(RTColor.primaryText)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(tint.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(surfaceID)
        .accessibilityLabel("\(label) \(value) \(unit)".trimmingCharacters(in: .whitespaces))
    }

    private func timeRange(_ session: StrainSession) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: session.startDate)) – \(f.string(from: session.endDate))"
    }

    private func iconName(for type: String) -> String {
        let t = type.lowercased()
        if t.contains("run") || t.contains("jog") { return "figure.run" }
        if t.contains("walk") { return "figure.walk" }
        if t.contains("cycl") || t.contains("bike") { return "figure.outdoor.cycle" }
        if t.contains("swim") { return "figure.pool.swim" }
        if t.contains("strength") || t.contains("weight") || t.contains("gym") {
            return "figure.strengthtraining.traditional"
        }
        if t.contains("hiit") || t.contains("functional") {
            return "figure.highintensity.intervaltraining"
        }
        if t.contains("yoga") { return "figure.yoga" }
        return "figure.run"
    }
}
