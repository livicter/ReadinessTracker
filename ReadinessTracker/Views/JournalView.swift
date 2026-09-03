import SwiftUI

/// Standalone journal screen for tracking behaviors and their correlation with recovery.
/// Reachable from Dashboard or Check-in tab.
struct JournalView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var entries: [JournalEntry] = []
    @State private var showingNewEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppleTheme.sectionSpacing) {
                        // New entry card
                        JournalEntryView { behaviors, notes in
                            let score = dataStore.history.first.map { data in
                                let history = dataStore.dataForSource(data.source, days: 30)
                                return ReadinessCalculator.calculateBreakdown(from: data, history: history).totalScore
                            }
                            let entry = JournalEntry(
                                date: Date(),
                                behaviors: behaviors,
                                notes: notes,
                                readinessScore: score
                            )
                            entries.insert(entry, at: 0)
                            saveEntries()
                            showingNewEntry = false
                        }
                        .slideIn(delay: 0)
                        
                        // Recent entries
                        if !entries.isEmpty {
                            SectionHeader(title: "Recent Entries")
                            
                            VStack(spacing: 12) {
                                ForEach(Array(entries.prefix(7).enumerated()), id: \.element.id) { index, entry in
                                    JournalEntryRow(entry: entry)
                                        .slideIn(delay: 0.1 + Double(index) * 0.05)
                                }
                            }
                        } else {
                            // Empty state
                            VStack(spacing: 16) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(RTColor.surfaceHighlight)
                                
                                Text("No journal entries yet")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Text("Track behaviors like alcohol, caffeine, stress, and recovery activities to see how they affect your readiness over time.")
                                    .font(.subheadline)
                                    .foregroundStyle(RTColor.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                        
                        // Behavior impact summary (when we have enough data)
                        if entries.count >= 3 {
                            behaviorImpactSection
                                .slideIn(delay: 0.2)
                        }
                    }
                    .padding(.horizontal, AppleTheme.horizontalMargin)
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RTColor.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: loadEntries)
        }
    }
    
    // MARK: - Persistence
    
    private let journalEntriesKey = "journal_entries"
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: journalEntriesKey)
        }
    }
    
    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: journalEntriesKey),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
    
    private var behaviorImpactSection: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Behavior Impact")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                
                // Group entries by behavior and calculate avg readiness
                let behaviorScores = calculateBehaviorImpact()
                
                ForEach(behaviorScores.sorted { $0.impact > $1.impact }, id: \.behavior) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(item.color)
                            .frame(width: 28, height: 28)
                            .background(item.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.behavior)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            
                            Text("\(item.count) entries · avg readiness \(Int(item.avgScore))")
                                .font(.caption)
                                .foregroundStyle(RTColor.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Impact indicator
                        let impactColor = item.impact > 0 ? RTColor.optimal : RTColor.warning
                        HStack(spacing: 2) {
                            Image(systemName: item.impact > 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10))
                            Text("\(Int(abs(item.impact)))")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(impactColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(impactColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func calculateBehaviorImpact() -> [(behavior: String, icon: String, color: Color, count: Int, avgScore: Double, impact: Double)] {
        let allScores = entries.compactMap { $0.readinessScore }
        let overallAvg = allScores.isEmpty ? 0 : Double(allScores.reduce(0, +)) / Double(allScores.count)
        
        var grouped: [JournalEntryView.Behavior: [Int]] = [:]
        for entry in entries {
            for behavior in entry.behaviors {
                if let score = entry.readinessScore {
                    grouped[behavior, default: []].append(score)
                }
            }
        }
        
        return grouped.map { behavior, scores in
            let avg = Double(scores.reduce(0, +)) / Double(scores.count)
            let impact = avg - overallAvg
            return (
                behavior: behavior.rawValue,
                icon: behavior.icon,
                color: behavior.color,
                count: scores.count,
                avgScore: avg,
                impact: impact
            )
        }
    }
}

// MARK: - Journal Entry Model

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let behaviors: [JournalEntryView.Behavior]
    let notes: String
    let readinessScore: Int?

    init(id: UUID = UUID(), date: Date, behaviors: [JournalEntryView.Behavior], notes: String, readinessScore: Int?) {
        self.id = id
        self.date = date
        self.behaviors = behaviors
        self.notes = notes
        self.readinessScore = readinessScore
    }
}

// Codable conformance so journal entries can persist to UserDefaults.
extension JournalEntryView.Behavior: Codable {}

// MARK: - Journal Entry Row

struct JournalEntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        NativeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(entry.date, style: .date)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    if let score = entry.readinessScore {
                        Text("\(score)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(scoreColor(score))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(scoreColor(score).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                // Behavior chips
                FlowLayout(spacing: 8) {
                    ForEach(entry.behaviors, id: \.self) { behavior in
                        HStack(spacing: 4) {
                            Image(systemName: behavior.icon)
                                .font(.system(size: 10))
                            Text(behavior.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundStyle(behavior.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(behavior.color.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(RTColor.secondaryText)
                        .lineLimit(2)
                }
            }
        }
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
