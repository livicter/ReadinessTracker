import SwiftUI

struct WeeklyReportView: View {
    let report: WeeklyReport
    @State private var isSharePresented = false

    private var dateRange: String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return "\(df.string(from: report.weekStart)) – \(df.string(from: report.weekEnd))"
    }

    private var trendText: String {
        switch report.readinessTrend {
        case .up: return "Improving"
        case .down: return "Declining"
        case .flat: return "Stable"
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppleTheme.sectionSpacing) {
                headerCard
                statGrid
                highlightsSection
                recommendationsSection
                shareButton
            }
            .padding(.horizontal, AppleTheme.horizontalMargin)
            .padding(.vertical, 12)
        }
        .background(AppBackground())
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RTColor.background, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(activityItems: [WeeklyReportGenerator.shared.formattedReport(report)])
        }
    }

    private var headerCard: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(dateRange)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(RTColor.secondaryText)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(report.avgReadiness))")
                        .font(AppleTheme.heroValue)
                        .foregroundStyle(RTColor.primaryText)

                    Text("% avg readiness")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }

                HStack(spacing: 6) {
                    Image(systemName: report.readinessTrend.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(report.readinessTrend.color)
                    Text(trendText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(RTColor.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: columns, spacing: 12) {
            StatGridItem(label: "Gym", value: "\(Int(report.avgGymScore))", unit: "%", trend: nil, icon: "dumbbell.fill", tint: RTColor.optimal)
            StatGridItem(label: "Work", value: "\(Int(report.avgWorkScore))", unit: "%", trend: nil, icon: "briefcase.fill", tint: RTColor.caution)
            StatGridItem(label: "Sleep", value: "\(Int(report.avgSleepScore))", unit: "%", trend: nil, icon: "bed.double.fill", tint: RTColor.sleep)
            if let cycles = report.avgSleepCycles {
                StatGridItem(label: "Cycles", value: String(format: "%.1f", cycles), unit: "avg", trend: nil, icon: "circle.hexagongrid.fill", tint: RTColor.sleep)
            }
            StatGridItem(label: "HRV", value: "\(Int(report.avgHRV))", unit: "ms", trend: nil, icon: "waveform.path.ecg", tint: RTColor.hrv)
            StatGridItem(label: "RHR", value: "\(Int(report.avgRHR))", unit: "bpm", trend: nil, icon: "heart.fill", tint: RTColor.warning)
            StatGridItem(label: "Strain", value: String(format: "%.1f", report.avgStrain), unit: "/21", trend: nil, icon: "flame.fill", tint: RTColor.strain)
            StatGridItem(label: "Workouts", value: "\(report.totalWorkouts)", unit: "", trend: nil, icon: "figure.run", tint: RTColor.optimal)
            StatGridItem(label: "Avg RPE", value: "\(Int(report.avgWorkoutRPE))", unit: "/10", trend: nil, icon: "gauge.with.dots.needle.67percent", tint: RTColor.caution)
        }
    }

    @ViewBuilder
    private var highlightsSection: some View {
        if !report.highlights.isEmpty {
            NativeCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Highlights")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.highlights, id: \.self) { highlight in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(RTColor.optimal)
                                    .frame(width: 26, height: 26)
                                    .background(RTColor.optimal.opacity(0.14))
                                    .clipShape(Circle())
                                Text(highlight)
                                    .font(.subheadline)
                                    .foregroundStyle(RTColor.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var recommendationsSection: some View {
        if !report.recommendations.isEmpty {
            NativeCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recommendations")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(RTColor.primaryText)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(report.recommendations, id: \.self) { rec in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(RTColor.caution)
                                    .frame(width: 26, height: 26)
                                    .background(RTColor.caution.opacity(0.14))
                                    .clipShape(Circle())
                                Text(rec)
                                    .font(.subheadline)
                                    .foregroundStyle(RTColor.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var shareButton: some View {
        Button {
            isSharePresented = true
        } label: {
            Label("Share Report", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .padding()
                .frame(maxWidth: .infinity)
                .background(RTColor.optimal)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous))
        }
    }
}
