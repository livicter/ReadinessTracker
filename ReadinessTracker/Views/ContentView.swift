import SwiftUI
import Charts
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var checkInPreferredTime: CheckInTime = .morning
    @State private var checkInRouteID = UUID()

    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                DashboardView()
            case 1:
                HistoryView()
            case 2:
                CheckInView(initialTime: checkInPreferredTime)
                    .id(checkInRouteID)
            default:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingPillTabBar(selection: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
        .tint(RTColor.optimal)
        .onAppear { UIFixture.installIfRequested() }
        .onOpenURL { url in
            switch AppDeepLink.parse(url) {
            case .checkIn(let time):
                openCheckIn(time)
            case .trends:
                openTrends()
            case .fitbitOAuth, .none:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppDeepLink.openCheckInNotification)) { note in
            let raw = note.userInfo?["time"] as? String
            let time = CheckInTime(rawValue: raw ?? "") ?? .morning
            openCheckIn(time)
        }
        .onReceive(NotificationCenter.default.publisher(for: AppDeepLink.openTrendsNotification)) { _ in
            openTrends()
        }
    }

    private func openCheckIn(_ time: CheckInTime) {
        checkInPreferredTime = time
        checkInRouteID = UUID()
        selectedTab = 2
    }

    private func openTrends() {
        selectedTab = 1
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
                        NavigationLink {
                            TrendDetailView(history: sourceHistory)
                        } label: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Browse Trends")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(RTColor.primaryText)
                                    Spacer()
                                    Text("7D · Avg / Min / Max")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(RTColor.tertiaryText)
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(RTColor.tertiaryText)
                                }
                                TrendChart(history: sourceHistory)
                                    .frame(height: 160)
                                    .allowsHitTesting(false)
                            }
                            .padding(.vertical, 4)
                        }
                        .accessibilityIdentifier(SurfaceID.historyTrendsLink)
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
                
                HStack(spacing: 10) {
                    historyMetricChip(icon: "bed.double", tint: RTColor.sleep, text: "\(String(format: "%.1f", data.sleepHours))h")
                    historyMetricChip(icon: "waveform.path.ecg", tint: RTColor.hrv, text: "\(Int(data.hrv))ms")
                    if data.deepSleepPercent > 0 {
                        historyMetricChip(
                            icon: "moon.fill",
                            tint: RTColor.sleep,
                            text: "D:\(Int(data.deepSleepPercent * 100))%"
                        )
                    }
                }
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
    

    private func historyMetricChip(icon: String, tint: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)
                .background(tint.opacity(0.14))
                .clipShape(Circle())
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(RTColor.secondaryText)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
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
                            Text("Using WHOOP through Apple Health.")
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
                        .accessibilityIdentifier(SurfaceID.settingsHealthKitConnect)
                    }
                    .accessibilityIdentifier(SurfaceID.settingsDataSources)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Fitbit", systemImage: "figure.walk")
                            Spacer()
                            StatusBadge(isActive: fitbit.isAuthenticated)
                        }
                        if let message = fitbit.errorMessage, !fitbit.isAuthenticated {
                            Text(message)
                                .font(.caption2)
                                .foregroundStyle(RTColor.secondaryText)
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
                            .accessibilityIdentifier(SurfaceID.settingsFitbitConnect)
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
                        settingsLinkLabel(title: "Coaching", icon: "lightbulb.fill", tint: RTColor.caution)
                    }
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        settingsLinkLabel(title: "Notifications", icon: "bell.fill", tint: Color(hex: "34C759"))
                    }
                }

                Section("Actions") {
                    Button {
                        Haptic.press()
                        Task { await refreshAllSources() }
                    } label: {
                        settingsLinkLabel(
                            title: isRefreshing ? "Refreshing…" : "Refresh Health Data",
                            icon: "arrow.clockwise",
                            tint: RTColor.optimal
                        )
                    }
                    .disabled(isRefreshing)

                    Button {
                        Haptic.press()
                        exportText = DataStore.shared.exportCSV()
                        showingExportSheet = true
                    } label: {
                        settingsLinkLabel(title: "Export CSV", icon: "square.and.arrow.up", tint: RTColor.hrv)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                    Text("Google Fit REST is not connected. Body metrics use Apple Health.")
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


    private func settingsLinkLabel(title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            AppIconTile(systemName: icon, color: tint, size: 30)
            Text(title)
                .font(.body)
                .foregroundStyle(RTColor.primaryText)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
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
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(isActive ? RTColor.optimal : RTColor.secondaryText)
            .background(
                Capsule()
                    .fill(isActive ? RTColor.optimal.opacity(0.16) : Color.primary.opacity(0.06))
            )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
