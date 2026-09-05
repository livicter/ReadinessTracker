import SwiftUI
import Charts
import UIKit

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
                .environment(\.symbolVariants, selectedTab == 2 ? .fill : .none)
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .environment(\.symbolVariants, selectedTab == 3 ? .fill : .none)
                .tag(3)
        }
        .tint(RTColor.optimal)
        .toolbarBackground(RTColor.surface, for: .tabBar)
        .onChange(of: selectedTab) { _ in Haptic.selectionChanged() }
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
                .onChange(of: selectedSource) { _ in Haptic.selectionChanged() }
                
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

                if dataStore.history.filter({ $0.source == selectedSource }).isEmpty {
                    emptyHistoryState
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
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
                NavigationStack {
                    if let report = WeeklyReportGenerator.shared.generateReport(for: selectedSource) {
                        WeeklyReportView(report: report)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Done") { showWeeklyReport = false }
                                }
                            }
                    } else {
                        weeklyReportUnavailable
                    }
                }
            }
            }
        }
    }

    // MARK: - Empty States
    private var emptyHistoryState: some View {
        VStack(spacing: 12) {
            AppEmptyState(
                systemImage: "calendar.badge.clock",
                title: "No Data for \(selectedSource.rawValue)",
                message: "Sync your device to start building history"
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var weeklyReportUnavailable: some View {
        AppEmptyState(
            systemImage: "doc.text",
            title: "Not Enough Data",
            message: "Need at least 3 days of data for a weekly report"
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
        .navigationTitle("Weekly Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { showWeeklyReport = false }
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
            .foregroundStyle(RTColor.optimal)
            .interpolationMethod(.catmullRom)
            
            PointMark(
                x: .value("Date", data.date, unit: .day),
                y: .value("Score", score)
            )
            .foregroundStyle(RTColor.optimal)
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
        ScoreZone(score: score).color
    }
}

struct SettingsView: View {
    @StateObject private var healthKit = HealthKitManager.shared
    @StateObject private var fitbit = FitbitManager.shared
    @State private var showingExportSheet = false
    @State private var exportText = ""
    @State private var isRefreshing = false
    @State private var settings = UserSettings.load()
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
            List {
                Section("Data Sources") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Apple Health", systemImage: "heart.fill")
                            Spacer()
                            StatusBadge(isActive: healthKit.isAuthorized)
                        }
                        Text(DashboardView.healthKitSourceLabel(healthKit.dataSource))
                            .font(.caption)
                            .foregroundStyle(RTColor.secondaryText)
                        if healthKit.dataSource.localizedCaseInsensitiveContains("whoop") {
                            Text("Official WHOOP API is not connected. Enable WHOOP → Apple Health sharing.")
                                .font(.caption2)
                                .foregroundStyle(RTColor.tertiaryText)
                        }
                        Button(healthKit.isAuthorized ? "Reconnect" : "Connect") {
                            Haptic.press()
                            Task {
                                await healthKit.requestAuthorization()
                                if !healthKit.isAuthorized, let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Fitbit", systemImage: "figure.walk")
                            Spacer()
                            StatusBadge(isActive: fitbit.isAuthenticated)
                        }
                        if let message = fitbit.errorMessage, !fitbit.isAuthenticated {
                            Text(message)
                                .font(.caption2)
                                .foregroundStyle(RTColor.warning)
                        }
                        HStack {
                            Button(fitbit.isAuthenticated ? "Refresh" : "Connect") {
                                Haptic.press()
                                Task {
                                    if fitbit.isAuthenticated {
                                        await fitbit.fetchTodayData()
                                    } else if let url = fitbit.authURL {
                                        openURL(url)
                                    }
                                }
                            }
                            if fitbit.isAuthenticated {
                                Button("Disconnect", role: .destructive) {
                                    Haptic.press()
                                    fitbit.disconnect()
                                }
                            }
                        }
                    }
                }

                Section("Privacy") {
                    Toggle("Track menstrual cycle", isOn: $settings.trackMenstrualCycle)
                        .onChange(of: settings.trackMenstrualCycle) { _ in
                            settings.save()
                        }
                    Text("Off by default. When on, cycle data can appear on Today and adjust recovery.")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
                
                Section("Insights") {
                    NavigationLink {
                        CoachingView()
                    } label: {
                        Label("Coaching", systemImage: "lightbulb.fill")
                    }
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }

                Section("Actions") {
                    Button {
                        Haptic.press()
                        Task { await refreshAllSources() }
                    } label: {
                        Label(isRefreshing ? "Refreshing…" : "Refresh Health Data", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                    
                    Button {
                        Haptic.press()
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
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    Text("Google Fit REST is not connected. Body & activity uses Apple Health.")
                        .font(.caption2)
                        .foregroundStyle(RTColor.tertiaryText)
                }
            }
            .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                ShareSheet(activityItems: [exportText])
            }
        }
    }

    private func refreshAllSources() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        if healthKit.isAuthorized {
            await healthKit.fetchTodayData()
            await healthKit.fetchHistoricalData(days: 30)
        }
        if fitbit.isAuthenticated {
            await fitbit.fetchTodayData()
        }
        isRefreshing = false
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
