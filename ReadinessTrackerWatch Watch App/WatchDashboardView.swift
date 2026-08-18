import SwiftUI

struct WatchDashboardView: View {
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var metadataStore = MetadataStore.shared
    @State private var selectedSource: DataSource = .appleWatch
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let data = dataStore.latest(for: selectedSource) {
                    let history = dataStore.dataForSource(selectedSource, days: 30)
                    let breakdown = ReadinessCalculator.calculateBreakdown(from: data, history: history)
                    let multiplier = metadataStore.multiplierFor(date: Date())
                    let adjustedScore = min(100, max(0, Int(Double(breakdown.totalScore) * multiplier)))
                    
                    // Hero score with animated ring
                    ZStack {
                        Circle()
                            .stroke(scoreColor(adjustedScore).opacity(0.2), lineWidth: 10)
                        
                        Circle()
                            .trim(from: 0, to: isLoading ? 0 : Double(adjustedScore) / 100)
                            .stroke(
                                scoreColor(adjustedScore),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .shadow(color: scoreColor(adjustedScore).opacity(0.4), radius: 3)
                        
                        VStack(spacing: 2) {
                            if isLoading {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 24)
                                    .shimmer()
                            } else {
                                Text("\(adjustedScore)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            
                            Text(readinessLabel(adjustedScore))
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                            
                            if !metadataStore.hasCheckedInToday(.morning) && !isLoading {
                                Circle()
                                    .fill(Color(hex: "FF9500"))
                                    .frame(width: 6, height: 6)
                                    .pulse(color: Color(hex: "FF9500").opacity(0.3))
                            }
                        }
                    }
                    .frame(width: 120, height: 120)
                    .padding(.vertical, 8)
                    
                    if multiplier != 1.0 && !isLoading {
                        let pct = Int((multiplier - 1.0) * 100)
                        let sign = pct >= 0 ? "+" : ""
                        Text("\(sign)\(pct)% check-in")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Metrics with slide-in
                    VStack(alignment: .leading, spacing: 8) {
                        WatchMetricRow(
                            icon: "bed.double.fill",
                            label: "Sleep",
                            value: isLoading ? "--" : "\(String(format: "%.1f", data.sleepHours))h",
                            color: Color(hex: "5E5CE6")
                        )
                        .slideIn(delay: 0.1)
                        
                        WatchMetricRow(
                            icon: "waveform.path.ecg",
                            label: "HRV",
                            value: isLoading ? "--" : "\(Int(data.hrv))ms",
                            color: Color(hex: "00D084")
                        )
                        .slideIn(delay: 0.15)
                        
                        WatchMetricRow(
                            icon: "heart.fill",
                            label: "RHR",
                            value: isLoading ? "--" : "\(Int(data.restingHeartRate))bpm",
                            color: Color(hex: "FF3B30")
                        )
                        .slideIn(delay: 0.2)
                        
                        if data.deepSleepPercent > 0 && !isLoading {
                            WatchMetricRow(
                                icon: "moon.fill",
                                label: "Deep",
                                value: "\(Int(data.deepSleepPercent * 100))%",
                                color: Color(hex: "BF5AF2")
                            )
                            .slideIn(delay: 0.25)
                        }
                    }
                    
                    // Quick check-in
                    if !metadataStore.hasCheckedInToday(.morning) && !isLoading {
                        NavigationLink("Morning Check-in", destination: WatchCheckInView(timeOfDay: .morning))
                            .font(.caption)
                            .padding(.top, 8)
                            .buttonStyle(BounceButtonStyle())
                    }
                } else {
                    if isLoading {
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 70)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .shimmer()
                            
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 16)
                                    .shimmer()
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 80, height: 12)
                                    .shimmer()
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        Text("Open iPhone app to sync data")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return Color(hex: "00D084")
        case 60..<80: return Color(hex: "34C759")
        case 40..<60: return Color(hex: "FF9500")
        default: return Color(hex: "FF3B30")
        }
    }
    
    private func readinessLabel(_ score: Int) -> String {
        switch score {
        case 80...100: return "Ready"
        case 60..<80: return "Good"
        case 40..<60: return "Easy"
        default: return "Rest"
        }
    }
}

struct WatchMetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.caption)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
    }
}

struct WatchCheckInView: View {
    let timeOfDay: CheckInTime
    @Environment(\.dismiss) private var dismiss
    
    @State private var subjectiveFeel = 3
    @State private var alcoholConsumed = false
    @State private var caffeineAfter2pm = false
    @State private var isSick = false
    @State private var workoutToday = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if timeOfDay == .morning {
                    Text("How do you feel?")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { i in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    subjectiveFeel = i
                                }
                            } label: {
                                Image(systemName: i <= subjectiveFeel ? "star.fill" : "star")
                                    .foregroundColor(i <= subjectiveFeel ? .yellow : .gray)
                                    .scaleEffect(i == subjectiveFeel ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.15), value: subjectiveFeel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Toggle("Alcohol?", isOn: $alcoholConsumed)
                    Toggle("Late caffeine?", isOn: $caffeineAfter2pm)
                    Toggle("Sick?", isOn: $isSick)
                } else {
                    Toggle("Workout today?", isOn: $workoutToday)
                }
                
                Button("Save") {
                    let metadata = UserMetadata(
                        timeOfDay: timeOfDay,
                        subjectiveFeel: timeOfDay == .morning ? subjectiveFeel : nil,
                        alcoholConsumed: alcoholConsumed,
                        caffeineAfter2pm: caffeineAfter2pm,
                        isSick: isSick,
                        workoutToday: workoutToday
                    )
                    MetadataStore.shared.save(metadata)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("\(timeOfDay.rawValue) Check-in")
    }
}
