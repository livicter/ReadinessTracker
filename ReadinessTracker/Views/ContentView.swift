import SwiftUI
import Charts

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            CheckInView()
                .tabItem {
                    Label("Check-in", systemImage: "checkmark.circle")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .toolbarBackground(RTColor.surface, for: .tabBar)
    }
}

struct HistoryView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var selectedSource: DataSource = .appleWatch
    @State private var showWeeklyReport = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                List {
                Picker("Source", selection: $selectedSource) {
                    ForEach(DataSource.allCases, id: \.self) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                
                Button {
                    showWeeklyReport = true
                } label: {
                    AppListRow(
                        icon: "doc.text",
                        color: RTColor.optimal,
                        label: "Weekly Report",
                        value: "Review last 7 days"
                    )
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                Section("Trends") {
                    if dataStore.history.count >= 2 {
                        let sourceHistory = dataStore.dataForSource(selectedSource, days: 30)
                        TrendChart(history: sourceHistory)
                            .frame(height: 200)
                    } else {
                        Text("Need more data for trends")
                            .foregroundColor(.secondary)
                    }
                }
                
                ForEach(dataStore.history.filter { $0.source == selectedSource }) { data in
                    NavigationLink(value: data) {
                        HistoryRow(data: data, history: dataStore.dataForSource(selectedSource, days: 30))
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: AppleTheme.cornerRadiusMedium, style: .continuous)
                            .fill(RTColor.surface)
                            .padding(.vertical, 2)
                    )
                    .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("History")
            .navigationDestination(for: DailyHealthData.self) { data in
                DayDetailView(
                    data: data,
                    history: dataStore.history.filter { $0.source == selectedSource }
                )
            }
            .navigationDestination(for: SleepDestination.self) { destination in
                SleepAnalysisView(
                    data: destination.data,
                    history: destination.history
                )
            }
            .sheet(isPresented: $showWeeklyReport) {
                if let report = WeeklyReportGenerator.shared.generateReport(for: selectedSource) {
                    NavigationStack {
                        WeeklyReportView(report: report)
                    }
                } else {
                    Text("Need at least 3 days of data for a weekly report")
                        .foregroundStyle(RTColor.secondaryText)
                        .padding()
                }
            }
            }
        }
    }
}

struct TrendChart: View {
    let history: [DailyHealthData]
    
    var body: some View {
        Chart(history) { data in
            let score = readinessScore(for: data)
            LineMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Score", score)
            )
            .foregroundStyle(Color.green)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Score", score)
            )
            .foregroundStyle(Color.green)
        }
        .chartYScale(domain: 0...100)
    }
    
    private func readinessScore(for data: DailyHealthData) -> Int {
        ReadinessCalculator.calculateBreakdown(from: data, history: history).totalScore
    }
}

struct HistoryRow: View {
    let data: DailyHealthData
    let history: [DailyHealthData]
    
    private var readinessScore: Int {
        ReadinessCalculator.calculateBreakdown(from: data, history: history).totalScore
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.date, style: .date)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Label("\(String(format: "%.1f", data.sleepHours))h", systemImage: "bed.double")
                    Label("\(Int(data.hrv))ms", systemImage: "waveform.path.ecg")
                    if data.deepSleepPercent > 0 {
                        Label("D:\(Int(data.deepSleepPercent * 100))%", systemImage: "moon.fill")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(readinessScore)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(scoreColor(readinessScore))
                
                if data.sleepEfficiency > 0 {
                    Text("Eff: \(Int(data.sleepEfficiency * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

struct SettingsView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var fitbit = FitbitManager.shared
    @State private var showingExportSheet = false
    @State private var exportText = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Data Sources") {
                    HStack {
                        Label("HealthKit", systemImage: "heart.fill")
                        Spacer()
                        StatusBadge(isActive: healthKit.isAuthorized)
                    }
                    
                    HStack {
                        Label("Fitbit", systemImage: "figure.walk")
                        Spacer()
                        StatusBadge(isActive: fitbit.isAuthenticated)
                    }
                }
                
                Section("Actions") {
                    Button {
                        Task {
                            await healthKit.fetchTodayData()
                        }
                    } label: {
                        Label("Refresh Health Data", systemImage: "arrow.clockwise")
                    }
                    .disabled(!healthKit.isAuthorized)
                    
                    Button {
                        exportText = DataStore.shared.exportCSV()
                        showingExportSheet = true
                    } label: {
                        Label("Export CSV", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [exportText])
            }
        }
    }
}

struct StatusBadge: View {
    let isActive: Bool
    
    var body: some View {
        Text(isActive ? "Connected" : "Not Connected")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
            .foregroundColor(isActive ? .green : .secondary)
            .cornerRadius(8)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
