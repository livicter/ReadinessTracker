import SwiftUI

/// Whoop-style sleep stage breakdown with horizontal stacked bar
/// Shows Awake, REM, Light, Deep with time labels and percentages
struct SleepStageBreakdown: View {
    let sleepHours: Double
    let deepPercent: Double
    let remPercent: Double
    let awakePercent: Double
    var efficiency: Double = 0.9
    
    private var lightPercent: Double {
        max(0, 1.0 - deepPercent - remPercent - awakePercent)
    }
    
    private var stages: [(label: String, percent: Double, color: Color, icon: String)] {
        [
            ("Awake", awakePercent, RTColor.caution, "eye.slash.fill"),
            ("REM", remPercent, Color(hex: "BF5AF2"), "moon.fill"),
            ("Light", lightPercent, Color(hex: "5E5CE6"), "bed.double.fill"),
            ("Deep", deepPercent, RTColor.optimal, "waveform.path.ecg")
        ]
    }
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Stages")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        
                        Text("\(String(format: "%.1f", sleepHours))h total sleep")
                            .font(.subheadline)
                            .foregroundStyle(RTColor.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Sleep score badge
                    let sleepScore = calculateSleepScore()
                    Text("\(sleepScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor(sleepScore))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(scoreColor(sleepScore).opacity(0.12))
                        .clipShape(Capsule())
                }
                
                // Stacked bar
                GeometryReader { geo in
                    let totalPercent = stages.reduce(0) { $0 + max(0, $1.percent) }
                    let width = geo.size.width
                    
                    HStack(spacing: 3) {
                        ForEach(stages.indices, id: \.self) { i in
                            let stage = stages[i]
                            let pct = totalPercent > 0 ? stage.percent / totalPercent : 0
                            let segmentWidth = max(4, width * CGFloat(pct))
                            
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(stage.color)
                                .frame(width: segmentWidth)
                                .overlay(
                                    // Show icon if segment is wide enough
                                    Group {
                                        if pct > 0.08 {
                                            Image(systemName: stage.icon)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                        }
                    }
                }
                .frame(height: 36)
                
                // Stage details grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(stages, id: \.label) { stage in
                        StageDetailItem(
                            label: stage.label,
                            percent: stage.percent,
                            hours: sleepHours * stage.percent,
                            color: stage.color,
                            icon: stage.icon
                        )
                    }
                }
            }
        }
    }
    
    private func calculateSleepScore() -> Int {
        let data = SleepData(
            hours: sleepHours,
            efficiency: efficiency,
            deepPercent: deepPercent,
            remPercent: remPercent,
            hrvDuringSleep: nil
        )
        return data.score()
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return RTColor.optimal
        case 60..<80: return RTColor.good
        case 40..<60: return RTColor.caution
        default: return RTColor.warning
        }
    }
}

private struct StageDetailItem: View {
    let label: String
    let percent: Double
    let hours: Double
    let color: Color
    let icon: String
    
    var body: some View {
        AppListRow(
            icon: icon,
            color: color,
            label: label,
            value: "\(Int(percent * 100))% · \(String(format: "%.1f", hours))h",
            showChevron: false
        )
    }
}